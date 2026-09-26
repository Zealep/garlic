package com.zealep.garlicbackend.catalogo.campania;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record CampaniaResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        LocalDate fechaInicio,
        LocalDate fechaFin,
        boolean activo,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
