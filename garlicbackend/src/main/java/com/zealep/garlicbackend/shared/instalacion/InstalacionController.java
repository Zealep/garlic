package com.zealep.garlicbackend.shared.instalacion;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Configuracion inicial de la app (fuera de /api: no requiere X-Empresa-Id).
 * Reemplazara el selector de empresa cuando exista autenticacion (JWT).
 */
@RestController
@Tag(name = "Instalacion")
public class InstalacionController {

    private final Instalacion instalacion;

    public InstalacionController(Instalacion instalacion) {
        this.instalacion = instalacion;
    }

    @GetMapping("/instalacion/empresas")
    @Operation(summary = "Empresas disponibles (instalacion dedicada: solo la del cliente)")
    public List<Instalacion.EmpresaOpcion> empresas() {
        return instalacion.empresas();
    }
}
