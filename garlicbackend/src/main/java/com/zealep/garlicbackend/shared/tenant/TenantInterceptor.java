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
 * Resuelve la empresa desde el header X-Empresa-Id y la publica en {@link TenantContext}.
 * En una instalacion dedicada solo acepta la empresa del cliente (403 para cualquier otra).
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
        String header = request.getHeader(TenantContext.HEADER);
        if (!StringUtils.hasText(header)) {
            throw new TenantRequiredException();
        }
        UUID empresaId;
        try {
            empresaId = UUID.fromString(header.trim());
        } catch (IllegalArgumentException e) {
            throw new TenantRequiredException();
        }
        if (instalacion.dedicada() && !instalacion.empresaDedicada().map(empresaId::equals).orElse(false)) {
            throw new EmpresaNoPermitidaException();
        }
        TenantContext.set(empresaId);
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        TenantContext.clear();
    }
}
