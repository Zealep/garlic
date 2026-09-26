package com.zealep.garlicbackend.lote;

import com.zealep.garlicbackend.catalogo.campania.Campania;
import com.zealep.garlicbackend.catalogo.campania.CampaniaService;
import com.zealep.garlicbackend.catalogo.localidad.LocalidadService;
import com.zealep.garlicbackend.catalogo.tipocompra.TipoCompraService;
import com.zealep.garlicbackend.catalogo.variedad.Variedad;
import com.zealep.garlicbackend.catalogo.variedad.VariedadService;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.Creacion;
import com.zealep.garlicbackend.shared.web.PageResponse;
import com.zealep.garlicbackend.tercero.agricultor.AgricultorService;
import com.zealep.garlicbackend.tercero.persona.PersonaService;
import com.zealep.garlicbackend.tercero.proveedor.ProveedorService;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@Transactional(readOnly = true)
public class LoteService {

    private static final Logger logger = LoggerFactory.getLogger(LoteService.class);

    private final LoteRepository repository;
    private final LoteMapper mapper;
    private final TenantProvider tenantProvider;
    private final CampaniaService campaniaService;
    private final VariedadService variedadService;
    private final LocalidadService localidadService;
    private final TipoCompraService tipoCompraService;
    private final AgricultorService agricultorService;
    private final ProveedorService proveedorService;
    private final PersonaService personaService;

    public LoteService(LoteRepository repository, LoteMapper mapper, TenantProvider tenantProvider,
            CampaniaService campaniaService, VariedadService variedadService, LocalidadService localidadService,
            TipoCompraService tipoCompraService, AgricultorService agricultorService,
            ProveedorService proveedorService, PersonaService personaService) {
        this.repository = repository;
        this.mapper = mapper;
        this.tenantProvider = tenantProvider;
        this.campaniaService = campaniaService;
        this.variedadService = variedadService;
        this.localidadService = localidadService;
        this.tipoCompraService = tipoCompraService;
        this.agricultorService = agricultorService;
        this.proveedorService = proveedorService;
        this.personaService = personaService;
    }

    public PageResponse<LoteResponse> listar(LoteFiltro filtro, Pageable pageable) {
        Pageable pagina = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Sort.by(Sort.Direction.DESC, "createdAt"));
        return PageResponse.of(repository.findAll(especificacion(filtro), pagina).map(mapper::toResponse));
    }

    public LoteResponse obtener(UUID id) {
        return mapper.toResponse(buscar(id));
    }

    /** Idempotente: si el id enviado por el cliente ya existe en la empresa, devuelve ese lote. */
    @Transactional
    public Creacion<LoteResponse> crear(LoteRequest request) {
        if (request.id() != null) {
            var existente = repository.findByIdAndEmpresaId(request.id(), tenantProvider.currentEmpresaId());
            if (existente.isPresent()) {
                return Creacion.existente(mapper.toResponse(existente.get()));
            }
        }
        Lote lote = new Lote();
        if (request.id() != null) {
            lote.asignarId(request.id());
        }
        lote.setEmpresaId(tenantProvider.currentEmpresaId());
        aplicar(request, lote);
        Lote guardado = repository.saveAndFlush(lote);
        logger.info("Lote registrado: {} ({}) zona {}", guardado.getCodigo(), guardado.getId(), guardado.getZona());
        return Creacion.nuevo(mapper.toResponse(guardado));
    }

    @Transactional
    public LoteResponse actualizar(UUID id, LoteRequest request) {
        Lote lote = buscar(id);
        if (!lote.isActivo()) {
            throw new ConflictException("El lote " + lote.getCodigo() + " esta anulado y no se puede modificar");
        }
        aplicar(request, lote);
        return mapper.toResponse(repository.saveAndFlush(lote));
    }

    /** Anula el lote: deja de contar para la validacion de zona duplicada. */
    @Transactional
    public LoteResponse anular(UUID id) {
        Lote lote = buscar(id);
        if (!lote.isActivo()) {
            throw new ConflictException("El lote " + lote.getCodigo() + " ya esta anulado");
        }
        lote.anular();
        logger.info("Lote anulado: {} ({})", lote.getCodigo(), id);
        return mapper.toResponse(repository.saveAndFlush(lote));
    }

    /** Para otros modulos (ej. evaluacion): lote existente y activo de la empresa. */
    public Lote referenciaActiva(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .filter(Lote::isActivo)
                .orElseThrow(() -> new BusinessException("Lote " + id + " no existe o esta anulado"));
    }

    private void aplicar(LoteRequest request, Lote lote) {
        Campania campania = campaniaService.referenciaActiva(request.campaniaId());
        Variedad variedad = variedadService.referenciaActiva(request.variedadId());
        if (!variedad.getCultivoId().equals(campania.getCultivoId())) {
            throw new BusinessException("La variedad " + variedad.getCodigo() + " no corresponde al cultivo de la campania");
        }
        validarDuplicados(request, campania, lote.getId());

        lote.setCampania(campania);
        lote.setCodigo(request.codigo());
        lote.setVariedad(variedad);
        lote.setAgricultor(agricultorService.referenciaActiva(request.agricultorId()));
        lote.setProveedor(request.proveedorId() == null ? null : proveedorService.referenciaActiva(request.proveedorId()));
        lote.setTitularLiquidacion(request.titularLiquidacion() == null ? null
                : personaService.obtenerOCrear(request.titularLiquidacion()));
        lote.setLocalidad(localidadService.referenciaActiva(request.localidadId()));
        lote.setZona(request.zona());
        lote.setLatitud(request.latitud());
        lote.setLongitud(request.longitud());
        lote.setMapsUrl(request.mapsUrl());
        lote.setTipoCompra(tipoCompraService.referenciaActiva(request.tipoCompraId()));
        lote.setFechaArrancado(request.fechaArrancado());
        lote.setFechaCorte(request.fechaCorte());
        lote.setFechaCarga(request.fechaCarga());
    }

    /**
     * Mensajes claros antes de llegar a la base; el indice unico parcial de la base es la red de seguridad.
     */
    private void validarDuplicados(LoteRequest request, Campania campania, UUID idActual) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        String zona = Lote.normalizarZona(request.zona());
        repository.buscarActivoEnZona(empresaId, campania.getId(), zona, idActual).ifPresent(otro -> {
            throw new ConflictException("Ya existe el lote " + otro.getCodigo() + " en la zona " + zona
                    + " para la campania " + campania.getCodigo());
        });
        String codigo = request.codigo().trim().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
        if (repository.existeCodigo(empresaId, campania.getId(), codigo, idActual)) {
            throw new ConflictException("Ya existe un lote con codigo " + codigo + " en la campania " + campania.getCodigo());
        }
    }

    private Lote buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException("Lote", id));
    }

    private Specification<Lote> especificacion(LoteFiltro filtro) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        return (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            p.add(cb.equal(root.get("empresaId"), empresaId));
            if (filtro.campaniaId() != null) {
                p.add(cb.equal(root.get("campania").get("id"), filtro.campaniaId()));
            }
            if (filtro.estado() != null) {
                p.add(cb.equal(root.get("estado"), filtro.estado()));
            }
            if (filtro.agricultorId() != null) {
                p.add(cb.equal(root.get("agricultor").get("id"), filtro.agricultorId()));
            }
            if (filtro.proveedorId() != null) {
                p.add(cb.equal(root.get("proveedor").get("id"), filtro.proveedorId()));
            }
            if (StringUtils.hasText(filtro.q())) {
                String patron = "%" + filtro.q().trim().toLowerCase(Locale.ROOT) + "%";
                var persona = root.join("agricultor", JoinType.INNER).join("persona", JoinType.INNER);
                p.add(cb.or(
                        cb.like(cb.lower(root.get("codigo")), patron),
                        cb.like(cb.lower(root.get("zonaNormalizada")), patron),
                        cb.like(cb.lower(persona.get("nombres")), patron),
                        cb.like(cb.lower(persona.get("numeroDocumento")), patron)));
            }
            return cb.and(p.toArray(Predicate[]::new));
        };
    }
}
