package com.zealep.garlicbackend.catalogo.tipodano;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos/tipos-dano")
@Tag(name = "Catalogo - Tipo de dano")
public class TipoDanoController extends AbstractCatalogoController<TipoDanoRequest, TipoDanoResponse> {

    public TipoDanoController(TipoDanoService service) {
        super(service);
    }
}
