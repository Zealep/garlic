package com.zealep.garlicbackend.shared.instalacion;

import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * El sistema es de una sola empresa (la agroexportadora del cliente): {@code garlic.instalacion.empresa-ruc}
 * indica cual. Todas las consultas se filtran por ella sin que la app la envie.
 * <p>
 * La columna {@code empresa_id} se conserva en el modelo (no cuesta nada y evita reestructurar la base).
 * Sin RUC configurado (solo en los tests de integracion) la empresa se toma del header {@code X-Empresa-Id},
 * para que cada test trabaje aislado en su propia empresa.
 */
@Component
public class Instalacion {

    private final JdbcClient jdbc;
    private final String ruc;
    private volatile Empresa empresa;

    public Instalacion(JdbcClient jdbc, @Value("${garlic.instalacion.empresa-ruc:}") String ruc) {
        this.jdbc = jdbc;
        this.ruc = ruc == null ? "" : ruc.trim();
    }

    /** Hay una empresa configurada (siempre, salvo en los tests de integracion). */
    public boolean configurada() {
        return StringUtils.hasText(ruc);
    }

    /** La empresa de la instalacion (se resuelve una vez, despues de Flyway). */
    public Optional<Empresa> empresa() {
        if (!configurada()) {
            return Optional.empty();
        }
        if (empresa == null) {
            empresa = jdbc.sql("SELECT id, ruc, razon_social FROM empresa WHERE ruc = :ruc AND activo")
                    .param("ruc", ruc)
                    .query(Empresa.class)
                    .optional()
                    .orElse(null);
        }
        return Optional.ofNullable(empresa);
    }

    public record Empresa(UUID id, String ruc, String razonSocial) {
    }
}
