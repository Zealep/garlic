package com.zealep.garlicbackend.catalogo.calibre;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

public record CalibreRequest(
        @NotNull UUID cultivoId,
        @NotBlank @Size(max = 30) String codigo,
        @NotBlank @Size(max = 120) String nombre,
        @PositiveOrZero Short orden,
        @DecimalMin("0.0") @Digits(integer = 4, fraction = 1) BigDecimal diametroMinMm,
        @DecimalMin("0.0") @Digits(integer = 4, fraction = 1) BigDecimal diametroMaxMm) {
}
