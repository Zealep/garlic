package com.zealep.garlicbackend.catalogo.tipoempaque;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record TipoEmpaqueResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        String nombre,
        Short orden,
        boolean activo,
        BigDecimal pesoReferencialKg,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
