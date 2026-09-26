package com.zealep.garlicbackend.shared.tenant;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsUtils;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Resuelve la empresa desde el header X-Empresa-Id y la publica en {@link TenantContext}.
 */
@Component
public class TenantInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (CorsUtils.isPreFlightRequest(request)) {
            return true; // el navegador no envia headers propios en el preflight CORS
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
