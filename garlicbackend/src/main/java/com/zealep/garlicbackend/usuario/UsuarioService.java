package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

/**
 * Reutiliza el CRUD generico (listar, obtener, crear, actualizar, baja logica, reactivar).
 * El email es unico en todo el sistema (restriccion de la base -> 409).
 */
@Service
public class UsuarioService extends AbstractCatalogoService<Usuario, UsuarioRequest, UsuarioResponse> {

    public UsuarioService(UsuarioRepository repository, UsuarioMapper mapper, TenantProvider tenantProvider) {
        super(repository, mapper, tenantProvider);
    }

    @Override
    protected String nombreRecurso() {
        return "Usuario";
    }

    @Override
    protected List<String> camposBusqueda() {
        return List.of("nombres", "email");
    }

    @Override
    protected Sort ordenPorDefecto() {
        return Sort.by("nombres");
    }
}
