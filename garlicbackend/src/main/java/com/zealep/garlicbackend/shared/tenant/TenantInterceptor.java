package com.zealep.garlicbackend.shared.tenant;

import com.zealep.garlicbackend.shared.instalacion.Instalacion;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsUtils;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Publica en {@link TenantContext} la empresa de la instalacion (el sistema es de una sola empresa).
 * Solo sin empresa configurada (tests de integracion) se toma del header {@code X-Empresa-Id}.
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
        if (instalacion.configurada()) {
            TenantContext.set(instalacion.empresa().map(Instalacion.Empresa::id).orElseThrow(() ->
                    new IllegalStateException("No existe la empresa de la instalacion (garlic.instalacion.empresa-ruc)")));
            return true;
        }
        String header = request.getHeader(TenantContext.HEADER);
        if (!StringUtils.hasText(header)) {
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
