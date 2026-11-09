package com.zealep.garlicbackend.acceso;

import com.zealep.garlicbackend.acceso.AccesoDtos.PerfilResponse;
import com.zealep.garlicbackend.acceso.AccesoDtos.SesionResponse;
import com.zealep.garlicbackend.acceso.AccesoDtos.UsuarioSesion;
import com.zealep.garlicbackend.shared.exception.BusinessException;
import com.zealep.garlicbackend.shared.instalacion.Instalacion;
import com.zealep.garlicbackend.shared.seguridad.DemasiadosIntentosException;
import com.zealep.garlicbackend.shared.seguridad.NoAutorizadoException;
import com.zealep.garlicbackend.shared.seguridad.TokenService;
import com.zealep.garlicbackend.shared.seguridad.UsuarioActual;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Login con DNI + clave. Devuelve un access token (8 h) y un refresh token (sesion de 30 dias que se renueva
 * con cada uso): asi el evaluador trabaja sin senal en campo y sincroniza al volver.
 */
@Service
public class AccesoService {

    private static final Logger logger = LoggerFactory.getLogger(AccesoService.class);
    static final String CREDENCIALES_INVALIDAS = "DNI o contraseña incorrectos";

    private final Credenciales credenciales;
    private final TokenService tokens;
    private final PasswordEncoder encoder;
    private final IntentosLogin intentos;
    private final Instalacion instalacion;
    /** Hash de una clave al azar: se compara aunque el DNI no exista (mismo tiempo de respuesta). */
    private final String senuelo;

    public AccesoService(Credenciales credenciales, TokenService tokens, PasswordEncoder encoder,
            IntentosLogin intentos, Instalacion instalacion) {
        this.credenciales = credenciales;
        this.tokens = tokens;
        this.encoder = encoder;
        this.intentos = intentos;
        this.instalacion = instalacion;
        this.senuelo = encoder.encode(UUID.randomUUID().toString());
    }

    @Transactional
    public SesionResponse login(String dniIngresado, String clave, String dispositivo) {
        String dni = dniIngresado.trim();
        if (intentos.bloqueado(dni)) {
            throw new DemasiadosIntentosException(
                    "Demasiados intentos fallidos. Espere 15 minutos o pida al administrador que restablezca su clave.");
        }
        Optional<Credenciales.Usuario> encontrado = credenciales.porDni(dni).filter(this::deLaInstalacion);
        String hash = encontrado.map(Credenciales.Usuario::claveHash).orElse(null);
        boolean claveOk = encoder.matches(clave, hash == null ? senuelo : hash) && hash != null;
        if (encontrado.isEmpty() || !claveOk) {
            intentos.fallo(dni);
            throw new NoAutorizadoException(CREDENCIALES_INVALIDAS);
        }
        Credenciales.Usuario u = encontrado.get();
        if (!u.activo()) {
            throw new NoAutorizadoException("Su usuario esta desactivado. Consulte con el administrador.");
        }
        intentos.exito(dni);
        credenciales.registrarAcceso(u.id());
        String refresh = tokens.nuevoRefresh();
        UUID sesion = credenciales.crearSesion(u.id(), TokenService.hash(refresh), tokens.vencimientoSesion(), dispositivo);
        logger.info("Inicio de sesion: usuario {}", u.id());
        return respuesta(u, sesion, refresh);
    }

    /** Canjea el refresh token por uno nuevo (rotacion) y un access token. El anterior deja de servir. */
    @Transactional
    public SesionResponse refrescar(String refreshToken) {
        Credenciales.Sesion sesion = credenciales.sesionPorToken(TokenService.hash(refreshToken))
                .filter(s -> !s.revocada() && s.expiraEn().isAfter(Instant.now()))
                .orElseThrow(() -> new NoAutorizadoException("Su sesion expiro. Vuelva a iniciar sesion."));
        Credenciales.Usuario u = credenciales.porId(sesion.usuarioId())
                .filter(Credenciales.Usuario::activo)
                .filter(this::deLaInstalacion)
                .orElseThrow(() -> new NoAutorizadoException("Su usuario esta desactivado. Consulte con el administrador."));
        String nuevo = tokens.nuevoRefresh();
        credenciales.rotar(sesion.id(), TokenService.hash(nuevo), tokens.vencimientoSesion());
        credenciales.registrarAcceso(u.id());
        return respuesta(u, sesion.id(), nuevo);
    }

    @Transactional
    public void logout(String refreshToken) {
        credenciales.sesionPorToken(TokenService.hash(refreshToken)).ifPresent(s -> credenciales.revocar(s.id()));
    }

    @Transactional(readOnly = true)
    public PerfilResponse perfil() {
        Credenciales.Usuario u = actual();
        return new PerfilResponse(UsuarioSesion.de(u), credenciales.empresa(u.empresaId()).orElse(null));
    }

    /** Cambia la propia clave; cierra las demas sesiones del usuario (otros celulares). */
    @Transactional
    public PerfilResponse cambiarClave(String actual, String nueva) {
        Credenciales.Usuario u = actual();
        if (u.claveHash() == null || !encoder.matches(actual, u.claveHash())) {
            throw new BusinessException("La contraseña actual no es correcta");
        }
        if (actual.equals(nueva)) {
            throw new BusinessException("La nueva contraseña debe ser distinta de la actual");
        }
        credenciales.guardarClave(u.id(), encoder.encode(nueva), false);
        credenciales.revocarTodas(u.id(), UsuarioActual.sesion().orElse(null));
        logger.info("Cambio de clave: usuario {}", u.id());
        return new PerfilResponse(
                UsuarioSesion.de(credenciales.porId(u.id()).orElseThrow()),
                credenciales.empresa(u.empresaId()).orElse(null));
    }

    private Credenciales.Usuario actual() {
        return credenciales.porId(UsuarioActual.requerido())
                .filter(Credenciales.Usuario::activo)
                .orElseThrow(() -> new NoAutorizadoException("Inicie sesion"));
    }

    private SesionResponse respuesta(Credenciales.Usuario u, UUID sesion, String refresh) {
        TokenService.Acceso acceso = tokens.acceso(u.id(), u.empresaId(), sesion, u.nombres(), u.admin());
        return new SesionResponse(acceso.token(), acceso.expiraEn(), refresh, UsuarioSesion.de(u),
                credenciales.empresa(u.empresaId()).orElse(null));
    }

    /** En la instalacion del cliente solo entran los usuarios de su empresa. */
    private boolean deLaInstalacion(Credenciales.Usuario u) {
        return instalacion.empresa().map(e -> e.id().equals(u.empresaId())).orElse(true);
    }
}
