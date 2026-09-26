package com.zealep.garlicbackend.catalogo.enfermedad;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record EnfermedadRequest(
        @NotNull UUID cultivoId,
        @NotBlank @Size(max = 30) String codigo,
        @NotBlank @Size(max = 120) String nombre,
        @PositiveOrZero Short orden,
        @Size(max = 150) String nombreCientifico,
        Boolean seTransmitePorSemilla,
        Boolean evaluarEnCampo) {
}
