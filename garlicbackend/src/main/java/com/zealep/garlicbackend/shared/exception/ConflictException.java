package com.zealep.garlicbackend.shared.exception;

/**
 * El recurso entra en conflicto con el estado actual (HTTP 409).
 */
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
