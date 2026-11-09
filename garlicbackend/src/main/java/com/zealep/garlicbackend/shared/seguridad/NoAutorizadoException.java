package com.zealep.garlicbackend.shared.seguridad;

/** Credenciales o sesion invalidas (401). */
public class NoAutorizadoException extends RuntimeException {

    public NoAutorizadoException(String message) {
        super(message);
    }
}
