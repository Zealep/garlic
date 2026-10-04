package com.zealep.garlicbackend.shared.instalacion;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Modo de instalacion. Con {@code garlic.instalacion.empresa-ruc} definido la instancia es
 * <b>dedicada</b> a una sola empresa: solo se ofrece esa empresa y el API rechaza cualquier otra.
 * Sin definir (desarrollo / SaaS) se listan todas las empresas activas.
 */
@Component
public class Instalacion {

    private final JdbcClient jdbc;
    private final String rucDedicado;
    private volatile UUID empresaDedicada;

    public Instalacion(JdbcClient jdbc, @Value("${garlic.instalacion.empresa-ruc:}") String rucDedicado) {
        this.jdbc = jdbc;
        this.rucDedicado = rucDedicado == null ? "" : rucDedicado.trim();
    }

    public boolean dedicada() {
        return StringUtils.hasText(rucDedicado);
    }

    /** Empresa de la instalacion dedicada (se resuelve una vez, despues de Flyway). */
    public Optional<UUID> empresaDedicada() {
        if (!dedicada()) {
            return Optional.empty();
        }
        if (empresaDedicada == null) {
            empresaDedicada = jdbc.sql("SELECT id FROM empresa WHERE ruc = :ruc AND activo")
                    .param("ruc", rucDedicado)
                    .query(UUID.class)
                    .optional()
                    .orElse(null);
        }
        return Optional.ofNullable(empresaDedicada);
    }

    /** Empresas que la app puede elegir en su configuracion inicial. */
    public List<EmpresaOpcion> empresas() {
        if (dedicada()) {
            return jdbc.sql("SELECT id, ruc, razon_social FROM empresa WHERE ruc = :ruc AND activo")
                    .param("ruc", rucDedicado)
                    .query(EmpresaOpcion.class)
                    .list();
        }
        return jdbc.sql("SELECT id, ruc, razon_social FROM empresa WHERE activo ORDER BY razon_social")
                .query(EmpresaOpcion.class)
                .list();
    }

    public record EmpresaOpcion(UUID id, String ruc, String razonSocial) {
    }
}
