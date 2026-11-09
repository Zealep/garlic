package com.zealep.garlicbackend.compra.dto;

import com.zealep.garlicbackend.compra.EstadoPago;
import java.math.BigDecimal;
import java.util.UUID;

/** Lote con materia prima comprada y saldo por pagar al agricultor (pantalla de inicio). */
public record PendientePago(
        UUID loteId,
        String loteCodigo,
        String zona,
        String agricultor,
        BigDecimal totalMp,
        BigDecimal totalPagado,
        BigDecimal saldo,
        EstadoPago estadoPago) {
}
