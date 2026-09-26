package com.zealep.garlicbackend.tercero.rol;

import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.PageResponse;
import com.zealep.garlicbackend.tercero.persona.Persona;
import com.zealep.garlicbackend.tercero.persona.PersonaMapper;
import com.zealep.garlicbackend.tercero.persona.PersonaRequest;
import com.zealep.garlicbackend.tercero.persona.PersonaService;
import jakarta.persistence.criteria.Join;
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
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * Alta y mantenimiento de un rol de persona. El alta recibe los datos de identidad:
 * si la persona ya existe (mismo documento) se reutiliza, si no se crea.
 */
@Transactional(readOnly = true)
public abstract class AbstractRolPersonaService<E extends RolPersonaEntity> {

    private static final Logger logger = LoggerFactory.getLogger(AbstractRolPersonaService.class);

    protected final RolPersonaRepository<E> repository;
    protected final PersonaService personaService;
    protected final PersonaMapper personaMapper;
    protected final TenantProvider tenantProvider;

    protected AbstractRolPersonaService(RolPersonaRepository<E> repository, PersonaService personaService,
            PersonaMapper personaMapper, TenantProvider tenantProvider) {
        this.repository = repository;
        this.personaService = personaService;
        this.personaMapper = personaMapper;
        this.tenantProvider = tenantProvider;
    }

    /** Nombre del rol para mensajes (ej. "agricultor"). */
    protected abstract String nombreRol();

    /** Nueva instancia vacia de la entidad del rol. */
    protected abstract E nuevaInstancia();

    public PageResponse<RolPersonaResponse> listar(String q, Boolean activo, Pageable pageable) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        Pageable pagina = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Sort.by("persona.nombres"));
        Specification<E> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("empresaId"), empresaId));
            if (activo != null) {
                predicates.add(cb.equal(root.get("activo"), activo));
            }
            if (StringUtils.hasText(q)) {
                Join<E, Persona> persona = root.join("persona");
                String patron = "%" + q.trim().toLowerCase(Locale.ROOT) + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(persona.get("nombres")), patron),
                        cb.like(cb.lower(persona.get("numeroDocumento")), patron)));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
        return PageResponse.of(repository.findAll(spec, pagina).map(this::toResponse));
    }

    public RolPersonaResponse obtener(UUID id) {
        return toResponse(buscar(id));
    }

    @Transactional
    public RolPersonaResponse crear(PersonaRequest request) {
        Persona persona = personaService.obtenerOCrear(request);
        if (persona.getId() != null && repository.existsByPersonaId(persona.getId())) {
            throw new ConflictException("La persona " + persona.getTipoDocumento() + " " + persona.getNumeroDocumento()
                    + " ya esta registrada como " + nombreRol() + " (si esta inactiva, reactivela)");
        }
        E rol = nuevaInstancia();
        rol.setEmpresaId(tenantProvider.currentEmpresaId());
        rol.setPersona(persona);
        E guardado = repository.saveAndFlush(rol);
        logger.info("{} registrado: {} (persona {})", nombreRol(), guardado.getId(), persona.getId());
        return toResponse(guardado);
    }

    /** Actualiza los datos de identidad de la persona asociada. */
    @Transactional
    public RolPersonaResponse actualizar(UUID id, PersonaRequest request) {
        E rol = buscar(id);
        personaService.actualizarDatos(rol.getPersona(), request);
        return toResponse(repository.saveAndFlush(rol));
    }

    @Transactional
    public void desactivar(UUID id) {
        E rol = buscar(id);
        rol.setActivo(false);
        repository.saveAndFlush(rol);
    }

    @Transactional
    public RolPersonaResponse activar(UUID id) {
        E rol = buscar(id);
        rol.setActivo(true);
        return toResponse(repository.saveAndFlush(rol));
    }

    /**
     * Para otros modulos que referencian el rol desde un request (ej. lote.agricultorId):
     * si no existe en la empresa o esta inactivo es un dato invalido del request (422).
     */
    public E referenciaActiva(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .filter(RolPersonaEntity::isActivo)
                .orElseThrow(() -> new BusinessException(
                        capitalizar(nombreRol()) + " " + id + " no existe o esta inactivo"));
    }

    protected E buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException(capitalizar(nombreRol()), id));
    }

    private RolPersonaResponse toResponse(E rol) {
        return new RolPersonaResponse(rol.getId(), rol.isActivo(), personaMapper.toResponse(rol.getPersona()),
                rol.getCreatedAt(), rol.getUpdatedAt());
    }

    private static String capitalizar(String s) {
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }
}
