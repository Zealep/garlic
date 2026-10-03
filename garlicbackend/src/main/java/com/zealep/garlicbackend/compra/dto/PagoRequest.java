package com.zealep.garlicbackend.compra.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Abono / adelanto al agricultor o proveedor por la materia prima.
 *
 * @param beneficiarioId persona que recibe el pago (agricultor, proveedor o titular de la liquidacion)
 * @param referencia     numero de operacion / voucher
 */
public record PagoRequest(
        @NotNull LocalDate fecha,
        @NotNull UUID condicionPagoId,
        @NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal monto,
        UUID beneficiarioId,
        @Size(max = 60) String referencia,
        @Size(max = 4000) String observacion) {
}
