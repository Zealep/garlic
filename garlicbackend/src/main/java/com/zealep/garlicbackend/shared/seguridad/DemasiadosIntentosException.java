package com.zealep.garlicbackend.shared.seguridad;

/** Login bloqueado temporalmente por intentos fallidos (429). */
public class DemasiadosIntentosException extends RuntimeException {

    public DemasiadosIntentosException(String message) {
        super(message);
    }
}
