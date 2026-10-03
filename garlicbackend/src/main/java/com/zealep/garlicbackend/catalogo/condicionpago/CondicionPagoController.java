package com.zealep.garlicbackend.catalogo.condicionpago;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/condiciones-pago")
@Tag(name = "Catalogo - Condicion de pago")
public class CondicionPagoController extends AbstractCatalogoController<CondicionPagoRequest, CondicionPagoResponse> {

    public CondicionPagoController(CondicionPagoService service) {
        super(service);
    }
}
