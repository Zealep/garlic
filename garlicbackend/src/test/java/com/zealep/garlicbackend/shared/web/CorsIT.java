package com.zealep.garlicbackend.shared.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.zealep.garlicbackend.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

/**
 * La app web (Flutter web) hace preflight CORS sin el header de empresa: no debe fallar.
 */
@TestPropertySource(properties = "garlic.cors.allowed-origins=http://localhost:*")
class CorsIT extends AbstractIntegrationTest {

    @Test
    void preflight_sinHeaderDeEmpresa_responde200ConCabecerasCors() throws Exception {
        mvc.perform(options("/api/v1/lotes")
                        .header("Origin", "http://localhost:5555")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "x-empresa-id,content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5555"));
    }
}
