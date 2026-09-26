package com.zealep.garlicbackend.catalogo.variedad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/variedades")
@Tag(name = "Catalogo - Variedad")
public class VariedadController extends AbstractCatalogoController<VariedadRequest, VariedadResponse> {

    public VariedadController(VariedadService service) {
        super(service);
    }
}
