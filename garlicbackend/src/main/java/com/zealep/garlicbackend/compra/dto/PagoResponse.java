package com.zealep.garlicbackend.compra.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record PagoResponse(
        UUID id,
        UUID loteId,
        LocalDate fecha,
        UUID condicionPagoId,
        String condicionPago,
        BigDecimal monto,
        UUID beneficiarioId,
        String beneficiario,
        String referencia,
        String observacion,
        Instant updatedAt) {
}
