package com.zealep.garlicbackend.compra.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record GastoResponse(
        UUID id,
        UUID loteId,
        UUID cargaId,
        UUID tipoGastoId,
        String tipoGasto,
        LocalDate fecha,
        BigDecimal monto,
        String descripcion,
        Instant updatedAt) {
}
