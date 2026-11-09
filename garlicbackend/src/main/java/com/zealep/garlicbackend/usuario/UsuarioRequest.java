package com.zealep.garlicbackend.usuario;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * @param dni   con el entra al sistema (unico)
 * @param email opcional
 * @param clave contraseña temporal al crear (el usuario la cambia al entrar); se ignora al actualizar
 */
public record UsuarioRequest(
        @NotBlank @Size(max = 150) String nombres,
        @NotBlank @Pattern(regexp = "\\d{8}", message = "debe tener 8 digitos") String dni,
        @Email @Size(max = 150) String email,
        @NotNull RolUsuario rol,
        @Size(min = 8, max = 72, message = "debe tener entre 8 y 72 caracteres") String clave) {
}
