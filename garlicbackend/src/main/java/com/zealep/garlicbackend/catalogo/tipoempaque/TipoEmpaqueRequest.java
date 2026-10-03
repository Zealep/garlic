package com.zealep.garlicbackend.catalogo.tipoempaque;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

public record TipoEmpaqueRequest(
        @NotNull UUID cultivoId,
        @NotBlank @Size(max = 30) String codigo,
        @NotBlank @Size(max = 120) String nombre,
        @PositiveOrZero Short orden,
        @DecimalMin(value = "0.0", inclusive = false) @Digits(integer = 6, fraction = 2) BigDecimal pesoReferencialKg) {
}
