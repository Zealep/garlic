package com.zealep.garlicbackend.catalogo.localidad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/localidades")
@Tag(name = "Catalogo - Localidad")
public class LocalidadController extends AbstractCatalogoController<LocalidadRequest, LocalidadResponse> {

    public LocalidadController(LocalidadService service) {
        super(service);
    }
}
