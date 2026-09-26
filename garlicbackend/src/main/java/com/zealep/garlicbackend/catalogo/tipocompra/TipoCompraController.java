package com.zealep.garlicbackend.catalogo.tipocompra;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/tipos-compra")
@Tag(name = "Catalogo - Tipo de compra")
public class TipoCompraController extends AbstractCatalogoController<TipoCompraRequest, TipoCompraResponse> {

    public TipoCompraController(TipoCompraService service) {
        super(service);
    }
}
