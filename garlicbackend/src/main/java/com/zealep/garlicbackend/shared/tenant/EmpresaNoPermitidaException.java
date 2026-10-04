package com.zealep.garlicbackend.shared.tenant;

/**
 * La instalacion es dedicada a otra empresa (HTTP 403).
 */
public class EmpresaNoPermitidaException extends RuntimeException {

    public EmpresaNoPermitidaException() {
        super("Esta instalacion no atiende a la empresa indicada");
    }
}
