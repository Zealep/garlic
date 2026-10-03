package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.compra.dto.ComprobanteResponse;
import com.zealep.garlicbackend.lote.Lote;
import com.zealep.garlicbackend.lote.LoteService;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.storage.ArchivosSubidos;
import com.zealep.garlicbackend.shared.storage.StorageService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.Creacion;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.web.multipart.MultipartFile;

/**
 * Fotos de respaldo de la compra: ticket de balanza (carga), voucher (pago) o recibo (gasto).
 */
@Service
@Transactional(readOnly = true)
public class ComprobanteService {

    private static final Logger logger = LoggerFactory.getLogger(ComprobanteService.class);

    private final ComprobanteRepository repository;
    private final CargaRepository cargaRepository;
    private final GastoVinculadoRepository gastoRepository;
    private final PagoRepository pagoRepository;
    private final LoteService loteService;
    private final StorageService storage;
    private final TenantProvider tenantProvider;

    public ComprobanteService(ComprobanteRepository repository, CargaRepository cargaRepository,
            GastoVinculadoRepository gastoRepository, PagoRepository pagoRepository, LoteService loteService,
            StorageService storage, TenantProvider tenantProvider) {
        this.repository = repository;
        this.cargaRepository = cargaRepository;
        this.gastoRepository = gastoRepository;
        this.pagoRepository = pagoRepository;
        this.loteService = loteService;
        this.storage = storage;
        this.tenantProvider = tenantProvider;
    }

    /**
     * @param id opcional: UUID del cliente. Si ya existe se devuelve el comprobante existente (reintento de sincronizacion).
     */
    @Transactional
    public Creacion<ComprobanteResponse> subir(UUID id, UUID loteId, EntidadComprobante entidad, UUID entidadId,
            MultipartFile archivo, Instant fechaCaptura) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        if (id != null) {
            var existente = repository.findByIdAndEmpresaId(id, empresaId);
            if (existente.isPresent()) {
                return Creacion.existente(ComprobanteResponse.from(existente.get()));
            }
        }
        Lote lote = loteService.referencia(loteId);
        if (!lote.isActivo()) {
            throw new ConflictException("El lote " + lote.getCodigo() + " esta anulado");
        }
        if (!existeEnLote(entidad, entidadId, lote.getId(), empresaId)) {
            throw new BusinessException("El registro " + entidadId + " (" + entidad + ") no existe en el lote; guardelo primero");
        }
        String extension = ArchivosSubidos.extensionImagen(archivo);

        String clave;
        try (InputStream contenido = archivo.getInputStream()) {
            clave = storage.guardar(empresaId + "/lotes/" + lote.getId(), extension, contenido);
        } catch (IOException e) {
            throw new UncheckedIOException("No se pudo leer el archivo subido", e);
        }
        ArchivosSubidos.alTerminar(TransactionSynchronization.STATUS_ROLLED_BACK, () -> storage.eliminar(clave));

        Comprobante nuevo = new Comprobante(empresaId, lote.getId(), entidad, entidadId, clave, fechaCaptura);
        if (id != null) {
            nuevo.asignarId(id);
        }
        Comprobante guardado = repository.save(nuevo);
        logger.info("Comprobante {} ({}) subido al lote {}", guardado.getId(), entidad, lote.getCodigo());
        return Creacion.nuevo(ComprobanteResponse.from(guardado));
    }

    public List<ComprobanteResponse> listar(UUID loteId) {
        return repository.findByLoteIdAndEmpresaIdOrderByCreatedAt(loteId, tenantProvider.currentEmpresaId())
                .stream().map(ComprobanteResponse::from).toList();
    }

    public Archivo archivo(UUID id) {
        Comprobante c = buscar(id);
        MediaType tipo = MediaTypeFactory.getMediaType(c.getUrlArchivo()).orElse(MediaType.APPLICATION_OCTET_STREAM);
        return new Archivo(storage.cargar(c.getUrlArchivo()), tipo);
    }

    @Transactional
    public void eliminar(UUID id) {
        Comprobante c = buscar(id);
        if (!loteService.referencia(c.getLoteId()).isActivo()) {
            throw new ConflictException("El lote esta anulado");
        }
        borrar(List.of(c));
    }

    /** Usado al eliminar una carga, gasto o pago. */
    @Transactional
    public void eliminarDeEntidad(UUID entidadId) {
        borrar(repository.findByEntidadIdAndEmpresaId(entidadId, tenantProvider.currentEmpresaId()));
    }

    private void borrar(List<Comprobante> comprobantes) {
        repository.deleteAll(comprobantes);
        List<String> claves = comprobantes.stream().map(Comprobante::getUrlArchivo).toList();
        ArchivosSubidos.alTerminar(TransactionSynchronization.STATUS_COMMITTED, () -> claves.forEach(storage::eliminar));
    }

    private boolean existeEnLote(EntidadComprobante entidad, UUID entidadId, UUID loteId, UUID empresaId) {
        return switch (entidad) {
            case CARGA -> cargaRepository.findByIdAndEmpresaId(entidadId, empresaId)
                    .filter(c -> c.getLoteId().equals(loteId)).isPresent();
            case GASTO -> gastoRepository.findByIdAndEmpresaId(entidadId, empresaId)
                    .filter(g -> g.getLoteId().equals(loteId)).isPresent();
            case PAGO -> pagoRepository.findByIdAndEmpresaId(entidadId, empresaId)
                    .filter(p -> p.getLoteId().equals(loteId)).isPresent();
        };
    }

    private Comprobante buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException("Comprobante", id));
    }

    /** Archivo listo para descargar. */
    public record Archivo(Resource contenido, MediaType tipo) {
    }
}
