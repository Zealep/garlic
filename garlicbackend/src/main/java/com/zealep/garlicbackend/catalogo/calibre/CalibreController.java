package com.zealep.garlicbackend.catalogo.calibre;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/calibres")
@Tag(name = "Catalogo - Calibre")
public class CalibreController extends AbstractCatalogoController<CalibreRequest, CalibreResponse> {

    public CalibreController(CalibreService service) {
        super(service);
    }
}
