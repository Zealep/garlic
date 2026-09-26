package com.zealep.garlicbackend.catalogo.cultivo;

import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/cultivos")
@Tag(name = "Catalogo - Cultivo")
public class CultivoController {

    private final CultivoService service;

    public CultivoController(CultivoService service) {
        this.service = service;
    }

    @GetMapping
    public List<CultivoResponse> listar() {
        return service.listar();
    }

    @GetMapping("/{id}")
    public CultivoResponse obtener(@PathVariable UUID id) {
        return service.obtener(id);
    }
}
