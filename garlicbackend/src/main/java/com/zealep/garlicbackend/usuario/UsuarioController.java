package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoController;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Usuarios: cualquiera los lista (evaluadores); crear, editar y restablecer clave solo un administrador. */
@RestController
@RequestMapping("/api/v1/usuarios")
@Tag(name = "Usuarios")
public class UsuarioController extends AbstractCatalogoController<UsuarioRequest, UsuarioResponse> {

    private final UsuarioService usuarios;

    public UsuarioController(UsuarioService service) {
        super(service);
        this.usuarios = service;
    }

    public record ClaveRequest(
            @NotBlank @Size(min = 8, max = 72, message = "debe tener entre 8 y 72 caracteres") String clave) {
    }

    @PutMapping("/{id}/clave")
    @Operation(summary = "Asignar una contraseña temporal (el usuario la cambia al entrar)")
    public UsuarioResponse restablecerClave(@PathVariable UUID id, @Valid @RequestBody ClaveRequest request) {
        return usuarios.restablecerClave(id, request.clave());
    }
}
