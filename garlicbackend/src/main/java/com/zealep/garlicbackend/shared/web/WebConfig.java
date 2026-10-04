package com.zealep.garlicbackend.shared.web;

import com.zealep.garlicbackend.shared.tenant.TenantContext;
import com.zealep.garlicbackend.shared.tenant.TenantInterceptor;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration(proxyBeanMethods = false)
public class WebConfig implements WebMvcConfigurer {

    private final TenantInterceptor tenantInterceptor;
    private final List<String> origenesPermitidos;

    public WebConfig(TenantInterceptor tenantInterceptor,
            @Value("${garlic.cors.allowed-origins:}") List<String> origenesPermitidos) {
        this.tenantInterceptor = tenantInterceptor;
        this.origenesPermitidos = origenesPermitidos;
    }

    /** Para la app web (Flutter web) y dashboards. Los origenes se configuran por ambiente. */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (origenesPermitidos.isEmpty()) {
            return;
        }
        registry.addMapping("/instalacion/**")
                .allowedOriginPatterns(origenesPermitidos.toArray(String[]::new))
                .allowedMethods("GET");
        registry.addMapping("/api/**")
                .allowedOriginPatterns(origenesPermitidos.toArray(String[]::new))
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .exposedHeaders(HttpHeaders.LOCATION, TenantContext.HEADER)
                .maxAge(3600);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(tenantInterceptor).addPathPatterns("/api/**");
    }
}
