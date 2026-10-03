package com.zealep.garlicbackend.catalogo.tipogasto;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/tipos-gasto")
@Tag(name = "Catalogo - Tipo de gasto")
public class TipoGastoController extends AbstractCatalogoController<TipoGastoRequest, TipoGastoResponse> {

    public TipoGastoController(TipoGastoService service) {
        super(service);
    }
}
