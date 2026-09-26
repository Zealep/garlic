package com.zealep.garlicbackend.tercero.persona;

import com.zealep.garlicbackend.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/personas")
@Tag(name = "Personas")
public class PersonaController {

    private final PersonaService service;

    public PersonaController(PersonaService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar (busca por nombres o numero de documento)")
    public PageResponse<PersonaResponse> listar(@RequestParam(required = false) String q, Pageable pageable) {
        return service.listar(q, pageable);
    }

    @GetMapping("/{id}")
    public PersonaResponse obtener(@PathVariable UUID id) {
        return service.obtener(id);
    }

    @GetMapping("/documento/{tipo}/{numero}")
    @Operation(summary = "Buscar por documento (ej. /documento/DNI/72790829)")
    public PersonaResponse obtenerPorDocumento(@PathVariable TipoDocumento tipo, @PathVariable String numero) {
        return service.obtenerPorDocumento(tipo, numero);
    }

    @PostMapping
    public ResponseEntity<PersonaResponse> crear(@Valid @RequestBody PersonaRequest request) {
        PersonaResponse creada = service.crear(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(creada.id()).toUri();
        return ResponseEntity.created(location).body(creada);
    }

    @PutMapping("/{id}")
    public PersonaResponse actualizar(@PathVariable UUID id, @Valid @RequestBody PersonaRequest request) {
        return service.actualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Eliminar (solo si no esta en uso)")
    public ResponseEntity<Void> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
