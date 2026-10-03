package com.zealep.garlicbackend.compra.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Gasto vinculado a la materia prima.
 *
 * @param cargaId null = gasto general del lote
 */
public record GastoRequest(
        UUID cargaId,
        @NotNull UUID tipoGastoId,
        @NotNull LocalDate fecha,
        @NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal monto,
        @Size(max = 250) String descripcion) {
}
