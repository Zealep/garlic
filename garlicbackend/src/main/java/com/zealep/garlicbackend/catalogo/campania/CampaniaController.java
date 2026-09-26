package com.zealep.garlicbackend.catalogo.campania;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/campanias")
@Tag(name = "Catalogo - Campania")
public class CampaniaController extends AbstractCatalogoController<CampaniaRequest, CampaniaResponse> {

    public CampaniaController(CampaniaService service) {
        super(service);
    }
}
