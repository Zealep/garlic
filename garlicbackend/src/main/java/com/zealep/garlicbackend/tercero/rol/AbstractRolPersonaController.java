package com.zealep.garlicbackend.tercero.rol;

import com.zealep.garlicbackend.shared.web.PageResponse;
import com.zealep.garlicbackend.tercero.persona.PersonaRequest;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

/**
 * Endpoints comunes de roles de persona. Cada subclase define {@code @RestController} y {@code @RequestMapping}.
 */
public abstract class AbstractRolPersonaController {

    protected final AbstractRolPersonaService<?> service;

    protected AbstractRolPersonaController(AbstractRolPersonaService<?> service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar (busca por nombres o numero de documento)")
    public PageResponse<RolPersonaResponse> listar(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Boolean activo,
            Pageable pageable) {
        return service.listar(q, activo, pageable);
    }

    @GetMapping("/{id}")
    public RolPersonaResponse obtener(@PathVariable UUID id) {
        return service.obtener(id);
    }

    @PostMapping
    @Operation(summary = "Registrar (reutiliza la persona si el documento ya existe)")
    public ResponseEntity<RolPersonaResponse> crear(@Valid @RequestBody PersonaRequest request) {
        RolPersonaResponse creado = service.crear(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(creado.id()).toUri();
        return ResponseEntity.created(location).body(creado);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar datos de identidad")
    public RolPersonaResponse actualizar(@PathVariable UUID id, @Valid @RequestBody PersonaRequest request) {
        return service.actualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Desactivar (baja logica)")
    public ResponseEntity<Void> desactivar(@PathVariable UUID id) {
        service.desactivar(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/activar")
    public RolPersonaResponse activar(@PathVariable UUID id) {
        return service.activar(id);
    }
}
