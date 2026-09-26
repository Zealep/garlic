package com.zealep.garlicbackend.catalogo.tipodano;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.util.UUID;

public record TipoDanoResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        String nombre,
        Short orden,
        boolean activo,
        Boolean esExcluyente,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
