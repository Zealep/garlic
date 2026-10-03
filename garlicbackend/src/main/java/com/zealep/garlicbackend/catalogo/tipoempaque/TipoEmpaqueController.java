package com.zealep.garlicbackend.catalogo.tipoempaque;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/tipos-empaque")
@Tag(name = "Catalogo - Tipo de empaque")
public class TipoEmpaqueController extends AbstractCatalogoController<TipoEmpaqueRequest, TipoEmpaqueResponse> {

    public TipoEmpaqueController(TipoEmpaqueService service) {
        super(service);
    }
}
