package com.zealep.garlicbackend.catalogo.clasecalidad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/clases-calidad")
@Tag(name = "Catalogo - Clase de calidad")
public class ClaseCalidadController extends AbstractCatalogoController<ClaseCalidadRequest, ClaseCalidadResponse> {

    public ClaseCalidadController(ClaseCalidadService service) {
        super(service);
    }
}
