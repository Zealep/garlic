package com.zealep.garlicbackend.shared.tenant;

import java.util.Optional;
import java.util.UUID;

/**
 * Mantiene la empresa (tenant) del request actual en el hilo que lo atiende.
 */
public final class TenantContext {

    public static final String HEADER = "X-Empresa-Id";

    private static final ThreadLocal<UUID> CURRENT = new ThreadLocal<>();

    private TenantContext() {
    }

    public static void set(UUID empresaId) {
        CURRENT.set(empresaId);
    }

    public static Optional<UUID> get() {
        return Optional.ofNullable(CURRENT.get());
    }

    public static void clear() {
        CURRENT.remove();
    }
}
