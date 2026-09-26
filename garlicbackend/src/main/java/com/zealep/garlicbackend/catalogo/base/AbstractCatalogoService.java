package com.zealep.garlicbackend.catalogo.base;

import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.PageResponse;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * CRUD generico de catalogos por empresa. Cada catalogo solo declara su entidad, DTOs y mapper;
 * las reglas propias se agregan sobrescribiendo {@link #validar(Object)}.
 */
@Transactional(readOnly = true)
public abstract class AbstractCatalogoService<E extends CatalogoEntity, REQ, RES> implements CatalogoService<REQ, RES> {

    private static final Logger logger = LoggerFactory.getLogger(AbstractCatalogoService.class);

    protected final CatalogoRepository<E> repository;
    protected final CatalogoMapper<E, REQ, RES> mapper;
    protected final TenantProvider tenantProvider;

    protected AbstractCatalogoService(
            CatalogoRepository<E> repository, CatalogoMapper<E, REQ, RES> mapper, TenantProvider tenantProvider) {
        this.repository = repository;
        this.mapper = mapper;
        this.tenantProvider = tenantProvider;
    }

    /** Nombre del recurso para los mensajes de error. */
    protected abstract String nombreRecurso();

    /** Campos de texto donde busca el filtro {@code q}. */
    protected List<String> camposBusqueda() {
        return List.of("codigo", "nombre");
    }

    /** Orden cuando el cliente no indica uno. */
    protected Sort ordenPorDefecto() {
        return Sort.by("orden", "nombre");
    }

    /** Reglas de negocio propias del catalogo (lanzar BusinessException si no se cumplen). */
    protected void validar(REQ request) {
        // sin reglas adicionales por defecto
    }

    @Override
    public PageResponse<RES> listar(CatalogoFiltro filtro, Pageable pageable) {
        Pageable pagina = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), ordenPorDefecto());
        return PageResponse.of(repository.findAll(especificacion(filtro), pagina).map(mapper::toResponse));
    }

    @Override
    public RES obtener(UUID id) {
        return mapper.toResponse(buscar(id));
    }

    @Override
    @Transactional
    public RES crear(REQ request) {
        validar(request);
        E entity = mapper.toEntity(request);
        entity.setEmpresaId(tenantProvider.currentEmpresaId());
        entity.setActivo(true);
        E guardado = repository.saveAndFlush(entity);
        logger.info("{} creado: {}", nombreRecurso(), guardado.getId());
        return mapper.toResponse(guardado);
    }

    @Override
    @Transactional
    public RES actualizar(UUID id, REQ request) {
        validar(request);
        E entity = buscar(id);
        mapper.actualizar(request, entity);
        return mapper.toResponse(repository.saveAndFlush(entity));
    }

    @Override
    @Transactional
    public void desactivar(UUID id) {
        E entity = buscar(id);
        entity.setActivo(false);
        repository.saveAndFlush(entity);
        logger.info("{} desactivado: {}", nombreRecurso(), id);
    }

    @Override
    @Transactional
    public RES activar(UUID id) {
        E entity = buscar(id);
        entity.setActivo(true);
        return mapper.toResponse(repository.saveAndFlush(entity));
    }

    /**
     * Para otros modulos que referencian este catalogo desde un request (ej. lote.variedadId):
     * si no existe en la empresa o esta inactivo es un dato invalido del request (422), no un 404.
     */
    public E referenciaActiva(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .filter(CatalogoEntity::isActivo)
                .orElseThrow(() -> new BusinessException(nombreRecurso() + " " + id + " no existe o esta inactivo"));
    }

    /**
     * Varias referencias a la vez (una sola consulta). Falla con 422 listando las que no existen
     * en la empresa o estan inactivas.
     */
    public Map<UUID, E> referenciasActivas(Collection<UUID> ids) {
        Map<UUID, E> encontrados = porIds(ids);
        encontrados.values().removeIf(e -> !e.isActivo());
        List<UUID> faltantes = ids.stream().filter(id -> !encontrados.containsKey(id)).distinct().toList();
        if (!faltantes.isEmpty()) {
            throw new BusinessException(nombreRecurso() + " no existe o esta inactivo: " + faltantes);
        }
        return encontrados;
    }

    /** Entidades de la empresa por id, activas o no (para mostrar datos historicos). */
    public Map<UUID, E> porIds(Collection<UUID> ids) {
        if (ids.isEmpty()) {
            return new HashMap<>();
        }
        UUID empresaId = tenantProvider.currentEmpresaId();
        Map<UUID, E> resultado = new HashMap<>();
        repository.findAllById(new HashSet<>(ids)).stream()
                .filter(e -> e.getEmpresaId().equals(empresaId))
                .forEach(e -> resultado.put(e.getId(), e));
        return resultado;
    }

    /** Todos los activos (sin paginar), opcionalmente de un cultivo. Para armar formularios. */
    public List<RES> listarActivos(UUID cultivoId) {
        return repository.findAll(especificacion(new CatalogoFiltro(null, true, cultivoId)), ordenPorDefecto())
                .stream().map(mapper::toResponse).toList();
    }

    protected E buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException(nombreRecurso(), id));
    }

    private Specification<E> especificacion(CatalogoFiltro filtro) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("empresaId"), empresaId));
            if (filtro.activo() != null) {
                predicates.add(cb.equal(root.get("activo"), filtro.activo()));
            }
            if (filtro.cultivoId() != null && tieneAtributo(root, "cultivoId")) {
                predicates.add(cb.equal(root.get("cultivoId"), filtro.cultivoId()));
            }
            if (StringUtils.hasText(filtro.q())) {
                String patron = "%" + filtro.q().trim().toLowerCase(Locale.ROOT) + "%";
                Predicate[] busqueda = camposBusqueda().stream()
                        .map(campo -> cb.like(cb.lower(root.get(campo)), patron))
                        .toArray(Predicate[]::new);
                predicates.add(cb.or(busqueda));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }

    private static boolean tieneAtributo(Root<?> root, String nombre) {
        return root.getModel().getAttributes().stream().anyMatch(a -> a.getName().equals(nombre));
    }
}
