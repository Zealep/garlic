package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.evaluacion.CatalogosEvaluacion.Resueltos;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionRequest;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResponse;
import com.zealep.garlicbackend.evaluacion.dto.EvaluacionResumen;
import com.zealep.garlicbackend.evaluacion.dto.FormularioEvaluacion;
import com.zealep.garlicbackend.evaluacion.evidencia.EvidenciaService;
import com.zealep.garlicbackend.lote.Lote;
import com.zealep.garlicbackend.lote.LoteService;
import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.Creacion;
import com.zealep.garlicbackend.shared.web.PageResponse;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import com.zealep.garlicbackend.usuario.UsuarioService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Punto 2 del protocolo: evaluacion de calidad del lote.
 * Mientras esta en BORRADOR el contenido completo se reemplaza en cada guardado; al cerrarla queda inmutable.
 */
@Service
@Transactional(readOnly = true)
public class EvaluacionService {

    private static final Logger logger = LoggerFactory.getLogger(EvaluacionService.class);

    private final EvaluacionLoteRepository repository;
    private final EvaluacionAssembler assembler;
    private final CatalogosEvaluacion catalogos;
    private final LoteService loteService;
    private final UsuarioService usuarioService;
    private final EvidenciaService evidenciaService;
    private final TenantProvider tenantProvider;

    public EvaluacionService(EvaluacionLoteRepository repository, EvaluacionAssembler assembler,
            CatalogosEvaluacion catalogos, LoteService loteService, UsuarioService usuarioService,
            EvidenciaService evidenciaService, TenantProvider tenantProvider) {
        this.repository = repository;
        this.assembler = assembler;
        this.catalogos = catalogos;
        this.loteService = loteService;
        this.usuarioService = usuarioService;
        this.evidenciaService = evidenciaService;
        this.tenantProvider = tenantProvider;
    }

    public FormularioEvaluacion formulario(UUID cultivoId) {
        return catalogos.formulario(cultivoId);
    }

    /** Bandeja general (dashboard): filtra por estado, lote y rango de fechas. */
    public PageResponse<EvaluacionResumen> listar(EvaluacionFiltro filtro, Pageable pageable) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        Pageable pagina = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(),
                        Sort.by(Sort.Order.desc("fechaEvaluacion"), Sort.Order.desc("createdAt")));
        Specification<EvaluacionLote> spec = (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            p.add(cb.equal(root.get("empresaId"), empresaId));
            if (filtro.estado() != null) {
                p.add(cb.equal(root.get("estado"), filtro.estado()));
            }
            if (filtro.loteId() != null) {
                p.add(cb.equal(root.get("lote").get("id"), filtro.loteId()));
            }
            if (filtro.desde() != null) {
                p.add(cb.greaterThanOrEqualTo(root.get("fechaEvaluacion"), filtro.desde()));
            }
            if (filtro.hasta() != null) {
                p.add(cb.lessThanOrEqualTo(root.get("fechaEvaluacion"), filtro.hasta()));
            }
            return cb.and(p.toArray(Predicate[]::new));
        };
        return PageResponse.of(repository.findAll(spec, pagina).map(assembler::toResumen));
    }

    public List<EvaluacionResumen> listarPorLote(UUID loteId) {
        return repository.findByLoteIdAndEmpresaIdOrderByFechaEvaluacionDescCreatedAtDesc(loteId, tenantProvider.currentEmpresaId())
                .stream().map(assembler::toResumen).toList();
    }

    public EvaluacionResponse obtener(UUID id) {
        EvaluacionLote ev = buscar(id);
        return assembler.toResponse(ev, catalogos.deEvaluacion(ev));
    }

    /** Idempotente: si el id enviado por el cliente ya existe en la empresa, devuelve esa evaluacion. */
    @Transactional
    public Creacion<EvaluacionResponse> crear(UUID loteId, EvaluacionRequest request) {
        if (request.id() != null) {
            var existente = repository.findByIdAndEmpresaId(request.id(), tenantProvider.currentEmpresaId());
            if (existente.isPresent()) {
                return Creacion.existente(assembler.toResponse(existente.get(), catalogos.deEvaluacion(existente.get())));
            }
        }
        Lote lote = loteService.referenciaActiva(loteId);
        EvaluacionLote ev = new EvaluacionLote(tenantProvider.currentEmpresaId(), lote);
        if (request.id() != null) {
            ev.asignarId(request.id());
        }
        Resueltos cat = aplicar(ev, request);
        EvaluacionLote guardada = repository.saveAndFlush(ev);
        logger.info("Evaluacion {} creada para lote {}", guardada.getId(), lote.getCodigo());
        return Creacion.nuevo(assembler.toResponse(guardada, cat));
    }

    @Transactional
    public EvaluacionResponse actualizar(UUID id, EvaluacionRequest request) {
        EvaluacionLote ev = buscarEditable(id);
        Resueltos cat = aplicar(ev, request);
        return assembler.toResponse(repository.saveAndFlush(ev), cat);
    }

    /** Valida que este completa y la deja inmutable. Idempotente: si ya estaba cerrada la devuelve. */
    @Transactional
    public EvaluacionResponse cerrar(UUID id) {
        EvaluacionLote actual = buscar(id);
        if (!actual.isBorrador()) {
            return assembler.toResponse(actual, catalogos.deEvaluacion(actual));
        }
        EvaluacionLote ev = buscarEditable(id);
        ReglasEvaluacion.validarCierre(ev, catalogos.enfermedadesObligatorias(ev.getLote().getCultivoId()));
        ev.cerrar();
        logger.info("Evaluacion {} cerrada", id);
        return assembler.toResponse(repository.saveAndFlush(ev), catalogos.deEvaluacion(ev));
    }

    /** Solo borradores; elimina tambien sus evidencias. */
    @Transactional
    public void eliminar(UUID id) {
        EvaluacionLote ev = buscarEditable(id);
        evidenciaService.eliminarDeEvaluacion(id);
        repository.delete(ev);
        logger.info("Evaluacion {} eliminada", id);
    }

    private Resueltos aplicar(EvaluacionLote ev, EvaluacionRequest request) {
        Resueltos cat = catalogos.validar(request, ev.getLote().getCultivoId());
        ReglasEvaluacion.validarContenido(request, cat.tiposDano());

        ev.setEvaluador(usuarioService.referenciaActiva(request.evaluadorId()));
        ev.setFechaEvaluacion(request.fechaEvaluacion());
        ev.setObservacion(request.observacion());

        // Muestras: se actualizan en sitio por numero para conservar sus evidencias.
        Set<Short> numeros = request.muestrasOVacio().stream().map(EvaluacionRequest.Muestra::numero).collect(Collectors.toSet());
        List<Muestra> quitadas = ev.getMuestras().stream().filter(m -> !numeros.contains(m.getNumero())).toList();
        evidenciaService.eliminarDeMuestras(quitadas.stream().map(Muestra::getId).filter(Objects::nonNull).toList());
        quitadas.forEach(ev::quitarMuestra);

        for (EvaluacionRequest.Muestra m : request.muestrasOVacio()) {
            Muestra muestra = ev.muestraONueva(m.numero());
            muestra.setObservacion(m.observacion());
            muestra.reemplazarCalidad(m.calidadOVacio().stream()
                    .map(c -> new PorcentajeCalidad(c.claseCalidadId(), escala(c.porcentaje())))
                    .toList());
            muestra.reemplazarCalibres(m.calibresOVacio().stream()
                    .map(c -> new PorcentajeCalibre(c.calibreId(), escala(c.porcentaje())))
                    .toList());
        }

        ev.reemplazarHumedad(request.humedadOVacio().stream()
                .map(h -> new HumedadObservada(h.tipoHumedadId(), h.nivel()))
                .toList());
        ev.reemplazarEmpastes(new LinkedHashSet<>(request.empastesOVacio()));
        ev.reemplazarDanos(new LinkedHashSet<>(request.danosOVacio()));
        ev.reemplazarSanidad(request.sanidadOVacio().stream()
                .map(s -> new SanidadObservada(s.enfermedadId(), s.presente(), s.porcentaje() == null ? null : escala(s.porcentaje())))
                .toList());
        return cat;
    }

    private EvaluacionLote buscarEditable(UUID id) {
        EvaluacionLote ev = buscar(id);
        if (!ev.isBorrador()) {
            throw new ConflictException("La evaluacion esta cerrada y no se puede modificar");
        }
        if (!ev.getLote().isActivo()) {
            throw new ConflictException("El lote " + ev.getLote().getCodigo() + " esta anulado");
        }
        return ev;
    }

    private EvaluacionLote buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException("Evaluacion", id));
    }

    /** Misma escala que numeric(5,2) para que la comparacion de filas sea estable. */
    private static BigDecimal escala(BigDecimal valor) {
        return valor.setScale(2, RoundingMode.HALF_UP);
    }
}
