package com.zealep.garlicbackend.shared.instalacion;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.zealep.garlicbackend.shared.tenant.TenantContext;
import com.zealep.garlicbackend.support.AbstractIntegrationTest;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

/**
 * Instalacion dedicada a una empresa: solo se ofrece esa empresa y el API rechaza las demas.
 */
@TestPropertySource(properties = "garlic.instalacion.empresa-ruc=" + InstalacionIT.RUC)
class InstalacionIT extends AbstractIntegrationTest {

    static final String RUC = "20999999991";

    private String cliente;

    @BeforeEach
    void setUp() {
        jdbc.sql("INSERT INTO empresa (ruc, razon_social) VALUES (:ruc, 'AGRO CLIENTE SAC') ON CONFLICT (ruc) DO NOTHING")
                .param("ruc", RUC).update();
        cliente = jdbc.sql("SELECT id FROM empresa WHERE ruc = :ruc").param("ruc", RUC).query(UUID.class).single().toString();
        nuevaEmpresa(); // otra empresa en la misma base
    }

    @Test
    void soloOfreceLaEmpresaDelCliente() throws Exception {
        mvc.perform(get("/instalacion/empresas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].ruc").value(RUC));
    }

    @Test
    void elApiRechazaOtraEmpresa() throws Exception {
        mvc.perform(get("/api/v1/catalogos/variedades").header(TenantContext.HEADER, cliente))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/catalogos/variedades").header(TenantContext.HEADER, nuevaEmpresa()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.title").value("Empresa no permitida"));
    }
}
