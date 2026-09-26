package com.zealep.garlicbackend.catalogo.tipoempaste;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class TipoEmpasteService extends AbstractCatalogoService<TipoEmpaste, TipoEmpasteRequest, TipoEmpasteResponse> {

    public TipoEmpasteService(TipoEmpasteRepository repository, TipoEmpasteMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Tipo de empaste";
    }
}
