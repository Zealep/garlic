package com.zealep.garlicbackend.shared.instalacion;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.zealep.garlicbackend.shared.tenant.TenantContext;
import com.zealep.garlicbackend.support.AbstractIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

/**
 * Sistema de una sola empresa: el API trabaja con la empresa de la instalacion sin que la app la envie.
 */
@TestPropertySource(properties = "garlic.instalacion.empresa-ruc=" + InstalacionIT.RUC)
class InstalacionIT extends AbstractIntegrationTest {

    static final String RUC = "20999999991";

    @BeforeEach
    void setUp() {
        jdbc.sql("INSERT INTO empresa (ruc, razon_social) VALUES (:ruc, 'AGRO CLIENTE SAC') ON CONFLICT (ruc) DO NOTHING")
                .param("ruc", RUC).update();
    }

    @Test
    void informaLaEmpresaDeLaInstalacion() throws Exception {
        mvc.perform(get("/instalacion/empresa"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ruc").value(RUC))
                .andExpect(jsonPath("$.razonSocial").value("AGRO CLIENTE SAC"));
    }

    @Test
    void elApiNoNecesitaHeaderDeEmpresa_eIgnoraOtraEmpresa() throws Exception {
        mvc.perform(get("/api/v1/catalogos/variedades")).andExpect(status().isOk());
        // un header de otra empresa no cambia la empresa con la que se trabaja
        String otra = nuevaEmpresa();
        jdbc.sql("INSERT INTO variedad (empresa_id, cultivo_id, codigo, nombre) VALUES (CAST(:e AS uuid), "
                        + "(SELECT id FROM cultivo WHERE codigo = 'AJO'), 'OTRA', 'OTRA')")
                .param("e", otra).update();
        mvc.perform(get("/api/v1/catalogos/variedades").param("q", "OTRA").header(TenantContext.HEADER, otra))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(0));
    }
}
