package com.zealep.garlicbackend.tercero.agricultor;

import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import com.zealep.garlicbackend.tercero.persona.PersonaMapper;
import com.zealep.garlicbackend.tercero.persona.PersonaService;
import com.zealep.garlicbackend.tercero.rol.AbstractRolPersonaService;
import org.springframework.stereotype.Service;

@Service
public class AgricultorService extends AbstractRolPersonaService<Agricultor> {

    public AgricultorService(AgricultorRepository repository, PersonaService personaService,
            PersonaMapper personaMapper, TenantProvider tenantProvider) {
        super(repository, personaService, personaMapper, tenantProvider);
    }

    @Override
    protected String nombreRol() {
        return "agricultor";
    }

    @Override
    protected Agricultor nuevaInstancia() {
        return new Agricultor();
    }
}
