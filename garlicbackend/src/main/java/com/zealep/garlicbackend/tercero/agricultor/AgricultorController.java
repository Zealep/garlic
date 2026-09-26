package com.zealep.garlicbackend.tercero.agricultor;

import com.zealep.garlicbackend.tercero.rol.AbstractRolPersonaController;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/agricultores")
@Tag(name = "Agricultores")
public class AgricultorController extends AbstractRolPersonaController {

    public AgricultorController(AgricultorService service) {
        super(service);
    }
}
