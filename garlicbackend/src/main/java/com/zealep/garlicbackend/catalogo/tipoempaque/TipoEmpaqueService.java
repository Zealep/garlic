package com.zealep.garlicbackend.catalogo.tipoempaque;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class TipoEmpaqueService extends AbstractCatalogoService<TipoEmpaque, TipoEmpaqueRequest, TipoEmpaqueResponse> {

    public TipoEmpaqueService(TipoEmpaqueRepository repository, TipoEmpaqueMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Tipo de empaque";
    }
}
