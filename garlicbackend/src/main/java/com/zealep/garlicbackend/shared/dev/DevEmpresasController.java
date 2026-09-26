package com.zealep.garlicbackend.shared.dev;

import java.util.List;
import java.util.UUID;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * SOLO perfil dev: lista las empresas para que la app pueda elegir el tenant en su configuracion
 * inicial mientras no exista autenticacion. Fuera de /api (no requiere X-Empresa-Id).
 */
@RestController
@Profile("dev")
public class DevEmpresasController {

    private final JdbcClient jdbc;

    public DevEmpresasController(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/dev/empresas")
    public List<EmpresaDev> empresas() {
        return jdbc.sql("SELECT id, ruc, razon_social FROM empresa WHERE activo ORDER BY razon_social")
                .query(EmpresaDev.class)
                .list();
    }

    public record EmpresaDev(UUID id, String ruc, String razonSocial) {
    }
}
