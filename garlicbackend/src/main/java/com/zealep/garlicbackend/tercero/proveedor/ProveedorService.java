package com.zealep.garlicbackend.tercero.proveedor;

import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.tercero.persona.PersonaMapper;
import com.zealep.garlicbackend.tercero.persona.PersonaService;
import com.zealep.garlicbackend.tercero.rol.AbstractRolPersonaService;
import org.springframework.stereotype.Service;

@Service
public class ProveedorService extends AbstractRolPersonaService<Proveedor> {

    public ProveedorService(ProveedorRepository repository, PersonaService personaService,
            PersonaMapper personaMapper, TenantProvider tenantProvider) {
        super(repository, personaService, personaMapper, tenantProvider);
    }

    @Override
    protected String nombreRol() {
        return "proveedor";
    }

    @Override
    protected Proveedor nuevaInstancia() {
        return new Proveedor();
    }
}
