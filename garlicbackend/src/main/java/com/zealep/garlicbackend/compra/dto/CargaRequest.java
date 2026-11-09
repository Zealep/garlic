package com.zealep.garlicbackend.compra.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Una carga (camion) de materia prima.
 *
 * @param destareKg kg a descontar por perdida del ajo (no mas que los kg); null = 0
 */
public record CargaRequest(
        @NotNull LocalDate fecha,
        @Size(max = 15) String placa,
        @NotNull @Positive @Digits(integer = 10, fraction = 2) BigDecimal kg,
        @PositiveOrZero Integer cantidadEmpaques,
        UUID tipoEmpaqueId,
        @NotNull @Positive @Digits(integer = 6, fraction = 4) BigDecimal precioKg,
        @PositiveOrZero @Digits(integer = 10, fraction = 2) BigDecimal destareKg,
        @Size(max = 4000) String observacion) {
}
