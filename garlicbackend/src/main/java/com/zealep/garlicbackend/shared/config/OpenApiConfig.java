package com.zealep.garlicbackend.shared.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
public class OpenApiConfig {

    @Bean
    OpenAPI garlicOpenApi() {
        return new OpenAPI().info(new Info()
                .title("Garlic API")
                .description("Garlic - Evaluacion, compra y pagos de lotes de ajo")
                .version("v1"));
    }
}
