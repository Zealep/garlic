package com.zealep.garlicbackend.shared.tenant;

import java.util.UUID;

/**
 * Punto unico para obtener la empresa actual. Hoy sale del header X-Empresa-Id;
 * al agregar autenticacion (JWT) solo cambia la implementacion.
 */
public interface TenantProvider {

    UUID currentEmpresaId();
}
