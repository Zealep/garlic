package com.zealep.garlicbackend.evaluacion.evidencia;

import com.zealep.garlicbackend.evaluacion.EvaluacionLote;
import com.zealep.garlicbackend.evaluacion.EvaluacionLoteRepository;
import com.zealep.garlicbackend.evaluacion.Muestra;
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
import java.util.Collection;
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
 * Fotos de la evaluacion. El archivo va al {@link StorageService}; la tabla guarda la clave.
 * Solo se agregan o eliminan mientras la evaluacion esta en BORRADOR.
 */
@Service
@Transactional(readOnly = true)
public class EvidenciaService {

    private static final Logger logger = LoggerFactory.getLogger(EvidenciaService.class);

    private final EvidenciaRepository repository;
    private final EvaluacionLoteRepository evaluacionRepository;
    private final StorageService storage;
    private final TenantProvider tenantProvider;

    public EvidenciaService(EvidenciaRepository repository, EvaluacionLoteRepository evaluacionRepository,
            StorageService storage, TenantProvider tenantProvider) {
        this.repository = repository;
        this.evaluacionRepository = evaluacionRepository;
        this.storage = storage;
        this.tenantProvider = tenantProvider;
    }

    /**
     * @param id opcional: UUID generado por el cliente. Si ya existe se devuelve la evidencia existente
     *           (reintento de sincronizacion) sin volver a guardar el archivo.
     */
    @Transactional
    public Creacion<EvidenciaResponse> subir(UUID id, UUID evaluacionId, MultipartFile archivo, Short muestraNumero,
            FactorEvidencia factor, String descripcion, Instant fechaCaptura) {
        if (id != null) {
            var existente = repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId());
            if (existente.isPresent()) {
                return Creacion.existente(EvidenciaResponse.from(existente.get()));
            }
        }
        EvaluacionLote evaluacion = evaluacionEditable(evaluacionId);
        Muestra muestra = muestraNumero == null ? null : evaluacion.muestra(muestraNumero)
                .orElseThrow(() -> new BusinessException("La muestra " + muestraNumero
                        + " no existe en la evaluacion; guardela primero"));
        String extension = ArchivosSubidos.extensionImagen(archivo);

        String clave;
        try (InputStream contenido = archivo.getInputStream()) {
            clave = storage.guardar(evaluacion.getEmpresaId() + "/" + evaluacion.getId(), extension, contenido);
        } catch (IOException e) {
            throw new UncheckedIOException("No se pudo leer el archivo subido", e);
        }
        // si la transaccion falla, no dejar el archivo huerfano
        ArchivosSubidos.alTerminar(TransactionSynchronization.STATUS_ROLLED_BACK, () -> storage.eliminar(clave));

        Evidencia nueva = new Evidencia(evaluacion, muestra, factor, clave, descripcion, fechaCaptura);
        if (id != null) {
            nueva.asignarId(id);
        }
        Evidencia guardada = repository.save(nueva);
        logger.info("Evidencia {} subida a evaluacion {}", guardada.getId(), evaluacionId);
        return Creacion.nuevo(EvidenciaResponse.from(guardada));
    }

    public List<EvidenciaResponse> listar(UUID evaluacionId) {
        return repository.findByEvaluacionIdAndEmpresaIdOrderByCreatedAt(evaluacionId, tenantProvider.currentEmpresaId())
                .stream().map(EvidenciaResponse::from).toList();
    }

    public ArchivoEvidencia archivo(UUID id) {
        Evidencia evidencia = buscar(id);
        MediaType tipo = MediaTypeFactory.getMediaType(evidencia.getUrlArchivo()).orElse(MediaType.APPLICATION_OCTET_STREAM);
        return new ArchivoEvidencia(storage.cargar(evidencia.getUrlArchivo()), tipo);
    }

    @Transactional
    public void eliminar(UUID id) {
        Evidencia evidencia = buscar(id);
        exigirBorrador(evidencia.getEvaluacion());
        borrar(List.of(evidencia));
    }

    /** Usado por la evaluacion al quitar muestras. */
    @Transactional
    public void eliminarDeMuestras(Collection<UUID> muestraIds) {
        if (!muestraIds.isEmpty()) {
            borrar(repository.findByMuestraIdIn(muestraIds));
        }
    }

    /** Usado por la evaluacion al eliminarse. */
    @Transactional
    public void eliminarDeEvaluacion(UUID evaluacionId) {
        borrar(repository.findByEvaluacionId(evaluacionId));
    }

    private void borrar(List<Evidencia> evidencias) {
        repository.deleteAll(evidencias);
        List<String> claves = evidencias.stream().map(Evidencia::getUrlArchivo).toList();
        // los archivos se borran solo si el borrado en base se confirma
        ArchivosSubidos.alTerminar(TransactionSynchronization.STATUS_COMMITTED, () -> claves.forEach(storage::eliminar));
    }

    private EvaluacionLote evaluacionEditable(UUID evaluacionId) {
        EvaluacionLote evaluacion = evaluacionRepository.findByIdAndEmpresaId(evaluacionId, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException("Evaluacion", evaluacionId));
        exigirBorrador(evaluacion);
        return evaluacion;
    }

    private static void exigirBorrador(EvaluacionLote evaluacion) {
        if (!evaluacion.isBorrador()) {
            throw new ConflictException("La evaluacion esta cerrada; no se pueden modificar sus evidencias");
        }
    }

    private Evidencia buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException("Evidencia", id));
    }

    /** Archivo listo para descargar. */
    public record ArchivoEvidencia(Resource contenido, MediaType tipo) {
    }
}
