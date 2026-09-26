package com.zealep.garlicbackend.catalogo.tipoempaste;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.util.UUID;

public record TipoEmpasteResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        String nombre,
        Short orden,
        boolean activo,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
