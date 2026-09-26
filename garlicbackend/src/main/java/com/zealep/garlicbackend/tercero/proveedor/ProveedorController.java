package com.zealep.garlicbackend.tercero.proveedor;

import com.zealep.garlicbackend.tercero.rol.AbstractRolPersonaController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/proveedores")
@Tag(name = "Proveedores")
public class ProveedorController extends AbstractRolPersonaController {

    public ProveedorController(ProveedorService service) {
        super(service);
    }
}
