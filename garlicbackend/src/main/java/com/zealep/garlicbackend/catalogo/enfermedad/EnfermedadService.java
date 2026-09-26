package com.zealep.garlicbackend.catalogo.enfermedad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class EnfermedadService extends AbstractCatalogoService<Enfermedad, EnfermedadRequest, EnfermedadResponse> {

    public EnfermedadService(EnfermedadRepository repository, EnfermedadMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Enfermedad";
    }
}
