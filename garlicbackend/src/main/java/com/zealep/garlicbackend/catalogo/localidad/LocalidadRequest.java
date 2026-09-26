package com.zealep.garlicbackend.catalogo.localidad;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record LocalidadRequest(
        @NotBlank @Size(max = 120) String nombre,
        @NotNull TipoLocalidad tipo,
        @Pattern(regexp = "\\d{6}", message = "debe tener 6 digitos") String ubigeo) {
}
