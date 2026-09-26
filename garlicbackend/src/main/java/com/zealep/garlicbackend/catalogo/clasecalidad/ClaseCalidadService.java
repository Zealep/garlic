package com.zealep.garlicbackend.catalogo.clasecalidad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class ClaseCalidadService extends AbstractCatalogoService<ClaseCalidad, ClaseCalidadRequest, ClaseCalidadResponse> {

    public ClaseCalidadService(ClaseCalidadRepository repository, ClaseCalidadMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Clase de calidad";
    }
}
