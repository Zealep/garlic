package com.zealep.garlicbackend.compra.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Carga con sus importes calculados (destare, kg netos y total). */
public record CargaResponse(
        UUID id,
        UUID loteId,
        LocalDate fecha,
        String placa,
        BigDecimal kg,
        int cantidadEmpaques,
        UUID tipoEmpaqueId,
        String tipoEmpaque,
        BigDecimal precioKg,
        BigDecimal destarePct,
        BigDecimal destareKg,
        BigDecimal kgNeto,
        BigDecimal importe,
        BigDecimal descuentoDestare,
        BigDecimal total,
        String observacion,
        Instant updatedAt) {
}
