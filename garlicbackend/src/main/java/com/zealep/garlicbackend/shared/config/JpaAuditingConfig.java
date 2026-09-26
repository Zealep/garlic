package com.zealep.garlicbackend.shared.config;

import java.util.Optional;
import java.util.UUID;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration(proxyBeanMethods = false)
@EnableJpaAuditing(auditorAwareRef = "auditorAware")
public class JpaAuditingConfig {

    /**
     * Sin autenticacion aun: created_by / updated_by quedan en null.
     * Cuando se agregue Spring Security se obtendra el id del usuario autenticado.
     */
    @Bean
    AuditorAware<UUID> auditorAware() {
        return Optional::empty;
    }
}
