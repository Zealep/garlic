package com.zealep.garlicbackend.acceso;

import com.zealep.garlicbackend.shared.instalacion.Instalacion;
import com.zealep.garlicbackend.shared.seguridad.AccesoProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Prepara al primer administrador al arrancar ({@code garlic.acceso.admin-dni} / {@code admin-clave-inicial}):
 * si aun no tiene clave le asigna la inicial (temporal: se pide cambiarla al entrar) y le da el rol ADMIN.
 * Nunca pisa una clave ya establecida. El usuario lo crea {@code R__instalacion.sql} (prod) o el seed (dev).
 */
@Component
public class InicializadorAcceso implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(InicializadorAcceso.class);

    private final Credenciales credenciales;
    private final PasswordEncoder encoder;
    private final AccesoProperties props;
    private final Instalacion instalacion;

    public InicializadorAcceso(Credenciales credenciales, PasswordEncoder encoder, AccesoProperties props,
            Instalacion instalacion) {
        this.credenciales = credenciales;
        this.encoder = encoder;
        this.props = props;
        this.instalacion = instalacion;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!StringUtils.hasText(props.adminDni()) || !instalacion.configurada()) {
            return;
        }
        var admin = credenciales.porDni(props.adminDni().trim())
                .filter(u -> instalacion.empresa().map(e -> e.id().equals(u.empresaId())).orElse(false));
        if (admin.isEmpty()) {
            logger.warn("No existe el usuario administrador con DNI {} en la empresa de la instalacion", props.adminDni());
            return;
        }
        var u = admin.get();
        credenciales.hacerAdmin(u.id());
        if (u.claveHash() == null) {
            if (!StringUtils.hasText(props.adminClaveInicial())) {
                logger.warn("El administrador {} no tiene clave: configure garlic.acceso.admin-clave-inicial", u.dni());
                return;
            }
            credenciales.guardarClave(u.id(), encoder.encode(props.adminClaveInicial()), true);
            logger.info("Clave inicial asignada al administrador {} (debe cambiarla al entrar)", u.dni());
        }
    }
}
