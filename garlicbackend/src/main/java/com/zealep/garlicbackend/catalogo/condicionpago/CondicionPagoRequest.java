package com.zealep.garlicbackend.catalogo.condicionpago;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record CondicionPagoRequest(
        @NotNull UUID cultivoId,
        @NotBlank @Size(max = 30) String codigo,
        @NotBlank @Size(max = 120) String nombre,
        @PositiveOrZero Short orden) {
}
