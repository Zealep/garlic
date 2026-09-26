package com.zealep.garlicbackend.catalogo.localidad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class LocalidadService extends AbstractCatalogoService<Localidad, LocalidadRequest, LocalidadResponse> {

    public LocalidadService(LocalidadRepository repository, LocalidadMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Localidad";
    }

    @Override
    protected List<String> camposBusqueda() {
        return List.of("nombre");
    }

    @Override
    protected Sort ordenPorDefecto() {
        return Sort.by("nombre");
    }
}
