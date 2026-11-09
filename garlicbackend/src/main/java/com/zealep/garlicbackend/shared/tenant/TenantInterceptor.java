package com.zealep.garlicbackend.shared.tenant;

import com.zealep.garlicbackend.shared.instalacion.Instalacion;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.zealep.garlicbackend.shared.seguridad.UsuarioActual;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsUtils;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Publica en {@link TenantContext} la empresa de la instalacion (el sistema es de una sola empresa).
 * Solo sin empresa configurada (tests de integracion) se toma del header {@code X-Empresa-Id} o, si no viene,
 * de la empresa del usuario logueado (claim del access token).
 */
@Component
public class TenantInterceptor implements HandlerInterceptor {

    private final Instalacion instalacion;

    public TenantInterceptor(Instalacion instalacion) {
        this.instalacion = instalacion;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (CorsUtils.isPreFlightRequest(request)) {
            return true; // el navegador no envia headers propios en el preflight CORS
        }
        Optional<UUID> empresaDelToken = UsuarioActual.empresa();
        if (instalacion.configurada()) {
            UUID empresa = instalacion.empresa().map(Instalacion.Empresa::id).orElseThrow(() ->
                    new IllegalStateException("No existe la empresa de la instalacion (garlic.instalacion.empresa-ruc)"));
            // un token de otra instalacion (otra clave) no pasa la firma; esto es una segunda barrera
            if (empresaDelToken.isPresent() && !empresaDelToken.get().equals(empresa)) {
                throw new AccessDeniedException("La sesion no pertenece a esta empresa");
            }
            TenantContext.set(empresa);
            return true;
        }
        String header = request.getHeader(TenantContext.HEADER);
        if (!StringUtils.hasText(header)) {
            if (empresaDelToken.isPresent()) {
                TenantContext.set(empresaDelToken.get());
                return true;
            }
            throw new TenantRequiredException();
        }
        try {
            TenantContext.set(UUID.fromString(header.trim()));
        } catch (IllegalArgumentException e) {
            throw new TenantRequiredException();
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        TenantContext.clear();
    }
}
