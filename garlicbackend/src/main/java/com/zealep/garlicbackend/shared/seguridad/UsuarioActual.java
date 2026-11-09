package com.zealep.garlicbackend.shared.seguridad;

import java.util.Optional;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;

/** El usuario autenticado de la request (del access token). */
public final class UsuarioActual {

    public static final String CLAIM_EMPRESA = "empresa";
    public static final String CLAIM_SESION = "sid";
    public static final String CLAIM_NOMBRES = "nombres";
    public static final String CLAIM_ADMIN = "admin";

    private UsuarioActual() {
    }

    public static Optional<Jwt> token() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getPrincipal() instanceof Jwt jwt ? Optional.of(jwt) : Optional.empty();
    }

    /** Id del usuario (claim {@code sub}); vacio si no hay login o el sub no es un id (tests). */
    public static Optional<UUID> id() {
        return token().flatMap(jwt -> uuid(jwt.getSubject()));
    }

    /** Id del usuario; 401 si no hay sesion. */
    public static UUID requerido() {
        return id().orElseThrow(() -> new NoAutorizadoException("Inicie sesion"));
    }

    public static Optional<UUID> sesion() {
        return token().flatMap(jwt -> uuid(jwt.getClaimAsString(CLAIM_SESION)));
    }

    public static Optional<UUID> empresa() {
        return token().flatMap(jwt -> uuid(jwt.getClaimAsString(CLAIM_EMPRESA)));
    }

    private static Optional<UUID> uuid(String valor) {
        try {
            return valor == null ? Optional.empty() : Optional.of(UUID.fromString(valor));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
