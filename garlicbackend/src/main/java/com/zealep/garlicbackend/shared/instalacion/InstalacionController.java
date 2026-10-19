package com.zealep.garlicbackend.shared.instalacion;

import com.zealep.garlicbackend.shared.exception.NotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Datos de la instalacion para la configuracion inicial de la app.
 */
@RestController
@Tag(name = "Instalacion")
public class InstalacionController {

    private final Instalacion instalacion;

    public InstalacionController(Instalacion instalacion) {
        this.instalacion = instalacion;
    }

    @GetMapping("/instalacion/empresa")
    @Operation(summary = "Empresa que usa el sistema")
    public Instalacion.Empresa empresa() {
        return instalacion.empresa()
                .orElseThrow(() -> new NotFoundException("La instalacion no tiene una empresa configurada (garlic.instalacion.empresa-ruc)"));
    }
}
