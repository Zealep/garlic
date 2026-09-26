package com.zealep.garlicbackend.catalogo.calibre;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import org.springframework.stereotype.Service;

@Service
public class CalibreService extends AbstractCatalogoService<Calibre, CalibreRequest, CalibreResponse> {

    public CalibreService(CalibreRepository repository, CalibreMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Calibre";
    }

    @Override
    protected void validar(CalibreRequest request) {
        if (request.diametroMinMm() != null && request.diametroMaxMm() != null
                && request.diametroMaxMm().compareTo(request.diametroMinMm()) <= 0) {
            throw new BusinessException("El diametro maximo debe ser mayor al diametro minimo");
        }
    }
}
