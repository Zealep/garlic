package com.zealep.garlicbackend.catalogo.calibre;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record CalibreResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        String nombre,
        Short orden,
        boolean activo,
        BigDecimal diametroMinMm,
        BigDecimal diametroMaxMm,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
