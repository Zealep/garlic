package com.zealep.garlicbackend.shared.exception;

import java.util.UUID;

public class NotFoundException extends RuntimeException {

    public NotFoundException(String recurso, UUID id) {
        super(recurso + " con id " + id + " no existe");
    }

    public NotFoundException(String message) {
        super(message);
    }
}
