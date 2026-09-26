package com.zealep.garlicbackend.shared.tenant;

import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class ContextTenantProvider implements TenantProvider {

    @Override
    public UUID currentEmpresaId() {
        return TenantContext.get().orElseThrow(TenantRequiredException::new);
    }
}
