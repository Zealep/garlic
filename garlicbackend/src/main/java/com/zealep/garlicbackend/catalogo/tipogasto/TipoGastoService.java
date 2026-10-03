package com.zealep.garlicbackend.catalogo.tipogasto;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class TipoGastoService extends AbstractCatalogoService<TipoGasto, TipoGastoRequest, TipoGastoResponse> {

    public TipoGastoService(TipoGastoRepository repository, TipoGastoMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Tipo de gasto";
    }
}
