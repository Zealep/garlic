package com.zealep.garlicbackend.catalogo.variedad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class VariedadService extends AbstractCatalogoService<Variedad, VariedadRequest, VariedadResponse> {

    public VariedadService(VariedadRepository repository, VariedadMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Variedad";
    }
}
