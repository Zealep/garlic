package com.zealep.garlicbackend.catalogo.tipohumedad;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/tipos-humedad")
@Tag(name = "Catalogo - Tipo de humedad")
public class TipoHumedadController extends AbstractCatalogoController<TipoHumedadRequest, TipoHumedadResponse> {

    public TipoHumedadController(TipoHumedadService service) {
        super(service);
    }
}
