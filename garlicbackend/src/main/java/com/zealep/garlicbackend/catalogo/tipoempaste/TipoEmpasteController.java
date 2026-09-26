package com.zealep.garlicbackend.catalogo.tipoempaste;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/tipos-empaste")
@Tag(name = "Catalogo - Tipo de empaste")
public class TipoEmpasteController extends AbstractCatalogoController<TipoEmpasteRequest, TipoEmpasteResponse> {

    public TipoEmpasteController(TipoEmpasteService service) {
        super(service);
    }
}
