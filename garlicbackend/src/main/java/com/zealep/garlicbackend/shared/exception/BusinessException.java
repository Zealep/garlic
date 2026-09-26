package com.zealep.garlicbackend.shared.exception;

/**
 * Regla de negocio incumplida (HTTP 422).
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
