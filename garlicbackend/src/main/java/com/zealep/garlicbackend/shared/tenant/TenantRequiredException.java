package com.zealep.garlicbackend.shared.tenant;

public class TenantRequiredException extends RuntimeException {

    public TenantRequiredException() {
        super("El header " + TenantContext.HEADER + " es obligatorio y debe ser un UUID valido");
    }
}
