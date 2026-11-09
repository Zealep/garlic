package com.zealep.garlicbackend.usuario;

import com.zealep.garlicbackend.acceso.Credenciales;
import com.zealep.garlicbackend.catalogo.base.AbstractCatalogoService;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.seguridad.UsuarioActual;
import com.zealep.garlicbackend.shared.tenant.TenantProvider;
import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reutiliza el CRUD generico (listar, obtener, crear, actualizar, baja logica, reactivar).
 * El DNI es unico (con el se entra) y el email, si se indica, tambien (restricciones de la base -> 409).
 * Crear / editar / restablecer clave solo lo hace un administrador (ver SecurityConfig).
 */
@Service
public class UsuarioService extends AbstractCatalogoService<Usuario, UsuarioRequest, UsuarioResponse> {

    private final Credenciales credenciales;
    private final PasswordEncoder encoder;
    private final EntityManager entityManager;

    public UsuarioService(UsuarioRepository repository, UsuarioMapper mapper, TenantProvider tenantProvider,
            Credenciales credenciales, PasswordEncoder encoder, EntityManager entityManager) {
        super(repository, mapper, tenantProvider);
        this.credenciales = credenciales;
        this.encoder = encoder;
        this.entityManager = entityManager;
    }

    @Override
    protected String nombreRecurso() {
        return "Usuario";
    }

    @Override
    protected List<String> camposBusqueda() {
        return List.of("nombres", "dni", "email");
    }

    @Override
    protected Sort ordenPorDefecto() {
        return Sort.by("nombres");
    }

    /** Alta con contraseña temporal (opcional: sin ella el usuario no puede entrar hasta que se le asigne). */
    @Override
    @Transactional
    public UsuarioResponse crear(UsuarioRequest request) {
        UsuarioResponse creado = super.crear(request);
        if (request.clave() != null) {
            credenciales.guardarClave(creado.id(), encoder.encode(request.clave()), true);
            return obtenerFresco(creado.id());
        }
        return creado;
    }

    @Override
    @Transactional
    public void desactivar(UUID id) {
        if (UsuarioActual.id().filter(id::equals).isPresent()) {
            throw new BusinessException("No puede desactivar su propio usuario");
        }
        super.desactivar(id);
        credenciales.revocarTodas(id, null);
    }

    /**
     * El administrador asigna una contraseña temporal (olvido o primer ingreso): el usuario debe cambiarla al
     * entrar y se cierran sus sesiones abiertas.
     */
    @Transactional
    public UsuarioResponse restablecerClave(UUID id, String clave) {
        Usuario usuario = buscar(id);
        credenciales.guardarClave(usuario.getId(), encoder.encode(clave), true);
        credenciales.revocarTodas(usuario.getId(), null);
        return obtenerFresco(id);
    }

    /** Relee el usuario (las columnas de acceso se escriben por SQL, fuera de la entidad). */
    private UsuarioResponse obtenerFresco(UUID id) {
        Usuario usuario = buscar(id);
        entityManager.refresh(usuario);
        return mapper.toResponse(usuario);
    }
}
