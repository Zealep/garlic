package com.zealep.garlicbackend.shared.config;

import com.zealep.garlicbackend.shared.seguridad.UsuarioActual;
import java.util.UUID;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration(proxyBeanMethods = false)
@EnableJpaAuditing(auditorAwareRef = "auditorAware")
public class JpaAuditingConfig {

    /** created_by / updated_by = el usuario del access token (vacio en procesos sin login). */
    @Bean
    AuditorAware<UUID> auditorAware() {
        return UsuarioActual::id;
    }
}
