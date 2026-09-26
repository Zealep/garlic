package com.zealep.garlicbackend.catalogo.tipohumedad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class TipoHumedadService extends AbstractCatalogoService<TipoHumedad, TipoHumedadRequest, TipoHumedadResponse> {

    public TipoHumedadService(TipoHumedadRepository repository, TipoHumedadMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Tipo de humedad";
    }
}
