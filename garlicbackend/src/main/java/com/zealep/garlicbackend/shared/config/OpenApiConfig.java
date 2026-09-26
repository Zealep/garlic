package com.zealep.garlicbackend.shared.config;

import com.zealep.garlicbackend.shared.tenant.TenantContext;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.parameters.HeaderParameter;
import org.springdoc.core.customizers.OperationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
public class OpenApiConfig {

    @Bean
    OpenAPI garlicOpenApi() {
        return new OpenAPI().info(new Info()
                .title("Garlic API")
                .description("SaaS agricola - Evaluacion de lotes de ajo")
                .version("v1"));
    }

    /** Documenta el header de tenant en todas las operaciones. */
    @Bean
    OperationCustomizer tenantHeaderCustomizer() {
        return (operation, handlerMethod) -> operation.addParametersItem(new HeaderParameter()
                .name(TenantContext.HEADER)
                .description("Id (UUID) de la empresa")
                .required(true)
                .schema(new StringSchema().format("uuid")));
    }
}
