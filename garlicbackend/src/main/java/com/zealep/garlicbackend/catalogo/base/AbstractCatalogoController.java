package com.zealep.garlicbackend.catalogo.base;

import com.zealep.garlicbackend.shared.web.PageResponse;
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
 * Endpoints REST comunes de catalogos. Cada subclase solo define {@code @RestController} y {@code @RequestMapping}.
 */
public abstract class AbstractCatalogoController<REQ, RES extends CatalogoResponse> {

    protected final CatalogoService<REQ, RES> service;

    protected AbstractCatalogoController(CatalogoService<REQ, RES> service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar (paginado y filtrado)")
    public PageResponse<RES> listar(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Boolean activo,
            @RequestParam(required = false) UUID cultivoId,
            Pageable pageable) {
        return service.listar(new CatalogoFiltro(q, activo, cultivoId), pageable);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtener por id")
    public RES obtener(@PathVariable UUID id) {
        return service.obtener(id);
    }

    @PostMapping
    @Operation(summary = "Crear")
    public ResponseEntity<RES> crear(@Valid @RequestBody REQ request) {
        RES creado = service.crear(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(creado.id())
                .toUri();
        return ResponseEntity.created(location).body(creado);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar")
    public RES actualizar(@PathVariable UUID id, @Valid @RequestBody REQ request) {
        return service.actualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Desactivar (baja logica)")
    public ResponseEntity<Void> desactivar(@PathVariable UUID id) {
        service.desactivar(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/activar")
    @Operation(summary = "Reactivar")
    public RES activar(@PathVariable UUID id) {
        return service.activar(id);
    }
}
