package com.zealep.garlicbackend.usuario;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UsuarioRequest(
        @NotBlank @Size(max = 150) String nombres,
        @Pattern(regexp = "\\d{8}", message = "debe tener 8 digitos") String dni,
        @NotBlank @Email @Size(max = 150) String email,
        @NotNull RolUsuario rol) {
}
