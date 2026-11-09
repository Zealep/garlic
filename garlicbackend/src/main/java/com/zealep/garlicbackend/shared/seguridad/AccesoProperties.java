package com.zealep.garlicbackend.shared.seguridad;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuracion del login ({@code garlic.acceso.*}).
 *
 * @param jwtSecret         clave para firmar los tokens (HS256). En produccion es obligatoria
 *                          ({@code GARLIC_JWT_SECRET}); vacia solo en tests: se genera una al azar.
 * @param duracionAcceso    vida del access token
 * @param duracionSesion    vida de la sesion (refresh token); se renueva con cada uso
 * @param adminDni          DNI del primer administrador (lo prepara {@code InicializadorAcceso})
 * @param adminClaveInicial clave temporal del primer administrador (se pide cambiarla al entrar)
 */
@ConfigurationProperties("garlic.acceso")
public record AccesoProperties(
        String jwtSecret,
        Duration duracionAcceso,
        Duration duracionSesion,
        String adminDni,
        String adminClaveInicial) {

    public AccesoProperties {
        duracionAcceso = duracionAcceso == null ? Duration.ofHours(8) : duracionAcceso;
        duracionSesion = duracionSesion == null ? Duration.ofDays(30) : duracionSesion;
    }
}
