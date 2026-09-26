package com.zealep.garlicbackend.catalogo.campania;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class CampaniaService extends AbstractCatalogoService<Campania, CampaniaRequest, CampaniaResponse> {

    public CampaniaService(CampaniaRepository repository, CampaniaMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Campania";
    }

    @Override
    protected List<String> camposBusqueda() {
        return List.of("codigo");
    }

    @Override
    protected Sort ordenPorDefecto() {
        return Sort.by(Sort.Direction.DESC, "codigo");
    }

    @Override
    protected void validar(CampaniaRequest request) {
        if (request.fechaInicio() != null && request.fechaFin() != null
                && request.fechaFin().isBefore(request.fechaInicio())) {
            throw new BusinessException("La fecha fin no puede ser anterior a la fecha inicio");
        }
    }
}
