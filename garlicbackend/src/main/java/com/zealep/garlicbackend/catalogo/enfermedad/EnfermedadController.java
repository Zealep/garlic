package com.zealep.garlicbackend.catalogo.enfermedad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/enfermedades")
@Tag(name = "Catalogo - Enfermedad")
public class EnfermedadController extends AbstractCatalogoController<EnfermedadRequest, EnfermedadResponse> {

    public EnfermedadController(EnfermedadService service) {
        super(service);
    }
}
