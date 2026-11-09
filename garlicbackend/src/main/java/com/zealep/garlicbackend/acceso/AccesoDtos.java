package com.zealep.garlicbackend.acceso;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

/** Requests y responses del login. */
public final class AccesoDtos {

    private AccesoDtos() {
    }

    public record LoginRequest(
            @NotBlank @Size(max = 15) String dni,
            @NotBlank @Size(max = 72) String clave,
            @Size(max = 200) String dispositivo) {
    }

    public record RefreshRequest(@NotBlank String refreshToken) {
    }

    public record CambioClaveRequest(
            @NotBlank String actual,
            @NotBlank @Size(min = 8, max = 72, message = "debe tener entre 8 y 72 caracteres") String nueva) {
    }

    public record UsuarioSesion(
            UUID id, String nombres, String dni, String email, boolean admin, boolean debeCambiarClave) {

        static UsuarioSesion de(Credenciales.Usuario u) {
            return new UsuarioSesion(u.id(), u.nombres(), u.dni(), u.email(), u.admin(), u.debeCambiarClave());
        }
    }

    /** Resultado del login o del refresh: tokens nuevos + quien entro. */
    public record SesionResponse(
            String accessToken,
            Instant accessExpiraEn,
            String refreshToken,
            UsuarioSesion usuario,
            EmpresaSesion empresa) {
    }

    public record PerfilResponse(UsuarioSesion usuario, EmpresaSesion empresa) {
    }
}
