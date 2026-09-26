package com.zealep.garlicbackend.catalogo.tipocompra;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class TipoCompraService extends AbstractCatalogoService<TipoCompra, TipoCompraRequest, TipoCompraResponse> {

    public TipoCompraService(TipoCompraRepository repository, TipoCompraMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Tipo de compra";
    }
}
