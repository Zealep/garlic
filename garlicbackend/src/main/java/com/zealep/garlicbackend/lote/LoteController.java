package com.zealep.garlicbackend.lote;

import com.zealep.garlicbackend.shared.web.Creacion;
import com.zealep.garlicbackend.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
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
@RequestMapping("/api/v1/lotes")
@Tag(name = "Lotes")
public class LoteController {

    private final LoteService service;

    public LoteController(LoteService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar (busca por codigo, zona o agricultor)")
    public PageResponse<LoteResponse> listar(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) UUID campaniaId,
            @RequestParam(required = false) EstadoLote estado,
            @RequestParam(required = false) UUID agricultorId,
            @RequestParam(required = false) UUID proveedorId,
            Pageable pageable) {
        return service.listar(new LoteFiltro(q, campaniaId, estado, agricultorId, proveedorId), pageable);
    }

    @GetMapping("/{id}")
    public LoteResponse obtener(@PathVariable UUID id) {
        return service.obtener(id);
    }

    @PostMapping
    @Operation(summary = "Registrar lote (409 si la zona ya tiene un lote activo; 200 si el id del cliente ya existe)")
    public ResponseEntity<LoteResponse> crear(@Valid @RequestBody LoteRequest request) {
        Creacion<LoteResponse> resultado = service.crear(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(resultado.valor().id()).toUri();
        return resultado.respuesta(location);
    }

    @PutMapping("/{id}")
    public LoteResponse actualizar(@PathVariable UUID id, @Valid @RequestBody LoteRequest request) {
        return service.actualizar(id, request);
    }

    @PostMapping("/{id}/anular")
    @Operation(summary = "Anular lote (libera la zona)")
    public LoteResponse anular(@PathVariable UUID id) {
        return service.anular(id);
    }
}
