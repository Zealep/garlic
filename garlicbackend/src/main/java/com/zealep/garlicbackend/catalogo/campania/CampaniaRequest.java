package com.zealep.garlicbackend.catalogo.campania;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;

public record CampaniaRequest(
        @NotNull UUID cultivoId,
        @NotBlank @Size(max = 20) String codigo,
        LocalDate fechaInicio,
        LocalDate fechaFin) {
}
