package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.util.UUID;

public record UsuarioResponse(
        UUID id,
        String nombres,
        String dni,
        String email,
        RolUsuario rol,
        boolean activo,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
