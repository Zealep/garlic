package com.zealep.garlicbackend.tercero.persona;

import com.zealep.garlicbackend.shared.exception.ConflictException;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.shared.web.PageResponse;
import java.util.Locale;
import java.util.Optional;
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
public class PersonaService {

    private static final Logger logger = LoggerFactory.getLogger(PersonaService.class);

    private final PersonaRepository repository;
    private final PersonaMapper mapper;
    private final TenantProvider tenantProvider;

    public PersonaService(PersonaRepository repository, PersonaMapper mapper, TenantProvider tenantProvider) {
        this.repository = repository;
        this.mapper = mapper;
        this.tenantProvider = tenantProvider;
    }

    public PageResponse<PersonaResponse> listar(String q, Pageable pageable) {
        UUID empresaId = tenantProvider.currentEmpresaId();
        Pageable pagina = pageable.getSort().isSorted()
                ? pageable
                : PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Sort.by("nombres"));
        Specification<Persona> spec = (root, query, cb) -> {
            var porEmpresa = cb.equal(root.get("empresaId"), empresaId);
            if (!StringUtils.hasText(q)) {
                return porEmpresa;
            }
            String patron = "%" + q.trim().toLowerCase(Locale.ROOT) + "%";
            return cb.and(porEmpresa, cb.or(
                    cb.like(cb.lower(root.get("nombres")), patron),
                    cb.like(cb.lower(root.get("numeroDocumento")), patron)));
        };
        return PageResponse.of(repository.findAll(spec, pagina).map(mapper::toResponse));
    }

    public PersonaResponse obtener(UUID id) {
        return mapper.toResponse(buscar(id));
    }

    public PersonaResponse obtenerPorDocumento(TipoDocumento tipo, String numero) {
        return porDocumento(tipo, numero)
                .map(mapper::toResponse)
                .orElseThrow(() -> new NotFoundException(
                        "Persona con " + tipo + " " + Persona.normalizarDocumento(numero) + " no existe"));
    }

    @Transactional
    public PersonaResponse crear(PersonaRequest request) {
        porDocumento(request.tipoDocumento(), request.numeroDocumento()).ifPresent(p -> {
            throw documentoDuplicado(request);
        });
        Persona persona = mapper.toEntity(request);
        persona.setEmpresaId(tenantProvider.currentEmpresaId());
        return mapper.toResponse(repository.saveAndFlush(persona));
    }

    @Transactional
    public PersonaResponse actualizar(UUID id, PersonaRequest request) {
        Persona persona = buscar(id);
        actualizarDatos(persona, request);
        return mapper.toResponse(repository.saveAndFlush(persona));
    }

    /** Elimina fisicamente; si la persona esta en uso la base lo impide (422). */
    @Transactional
    public void eliminar(UUID id) {
        repository.delete(buscar(id));
        repository.flush();
        logger.info("Persona eliminada: {}", id);
    }

    /**
     * Devuelve la persona con ese documento (actualizando nombres/telefono) o la crea.
     * Lo usan los roles (agricultor, proveedor) y el lote (titular de liquidacion).
     */
    @Transactional
    public Persona obtenerOCrear(PersonaRequest request) {
        return porDocumento(request.tipoDocumento(), request.numeroDocumento())
                .map(existente -> {
                    existente.setNombres(request.nombres());
                    if (request.telefono() != null) {
                        existente.setTelefono(request.telefono());
                    }
                    return existente;
                })
                .orElseGet(() -> {
                    Persona nueva = mapper.toEntity(request);
                    nueva.setEmpresaId(tenantProvider.currentEmpresaId());
                    return repository.save(nueva);
                });
    }

    /** Actualiza los datos de identidad validando que el nuevo documento no pertenezca a otra persona. */
    @Transactional
    public void actualizarDatos(Persona persona, PersonaRequest request) {
        porDocumento(request.tipoDocumento(), request.numeroDocumento())
                .filter(otra -> !otra.getId().equals(persona.getId()))
                .ifPresent(otra -> {
                    throw documentoDuplicado(request);
                });
        mapper.actualizar(request, persona);
    }

    private Optional<Persona> porDocumento(TipoDocumento tipo, String numero) {
        return repository.findByEmpresaIdAndTipoDocumentoAndNumeroDocumento(
                tenantProvider.currentEmpresaId(), tipo, Persona.normalizarDocumento(numero));
    }

    private Persona buscar(UUID id) {
        return repository.findByIdAndEmpresaId(id, tenantProvider.currentEmpresaId())
                .orElseThrow(() -> new NotFoundException("Persona", id));
    }

    private static ConflictException documentoDuplicado(PersonaRequest request) {
        return new ConflictException("Ya existe una persona con " + request.tipoDocumento() + " "
                + Persona.normalizarDocumento(request.numeroDocumento()));
    }
}
