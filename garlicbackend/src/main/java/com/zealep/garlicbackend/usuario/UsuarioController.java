package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/usuarios")
@Tag(name = "Usuarios")
public class UsuarioController extends AbstractCatalogoController<UsuarioRequest, UsuarioResponse> {

    public UsuarioController(UsuarioService service) {
        super(service);
    }
}
