package com.zealep.garlicbackend.catalogo.condicionpago;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class CondicionPagoService extends AbstractCatalogoService<CondicionPago, CondicionPagoRequest, CondicionPagoResponse> {

    public CondicionPagoService(CondicionPagoRepository repository, CondicionPagoMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Condicion de pago";
    }
}
