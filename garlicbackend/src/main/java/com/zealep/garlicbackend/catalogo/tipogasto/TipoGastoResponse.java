package com.zealep.garlicbackend.catalogo.tipogasto;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.util.UUID;

public record TipoGastoResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        String nombre,
        Short orden,
        boolean activo,
        Boolean porCarga,
        Boolean requiereDescripcion,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
