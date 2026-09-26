package com.zealep.garlicbackend.catalogo.tipodano;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class TipoDanoService extends AbstractCatalogoService<TipoDano, TipoDanoRequest, TipoDanoResponse> {

    public TipoDanoService(TipoDanoRepository repository, TipoDanoMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Tipo de dano";
    }
}
