package com.zealep.garlicbackend.tercero;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.zealep.garlicbackend.shared.tenant.TenantContext;
import com.zealep.garlicbackend.support.AbstractIntegrationTest;
import java.util.concurrent.ThreadLocalRandom;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Personas, agricultores y proveedores contra Postgres real.
 */
class TerceroIT extends AbstractIntegrationTest {

    private String empresa;
    private String otraEmpresa;
    private String dni;

    @BeforeEach
    void setUp() {
        empresa = nuevaEmpresa();
        otraEmpresa = nuevaEmpresa();
        dni = String.valueOf(ThreadLocalRandom.current().nextInt(10_000_000, 99_999_999));
    }

    @Test
    void agricultorYProveedor_conMismoDni_compartenLaPersona() throws Exception {
        String agricultor = crear("/api/v1/agricultores", identidad(dni, "Kevin", "999111222"));
        String proveedor = crear("/api/v1/proveedores", identidad(dni, "Kevin Quispe", null));

        String personaAgr = JsonPath.read(agricultor, "$.persona.id");
        String personaProv = JsonPath.read(proveedor, "$.persona.id");
        assertThat(personaProv).isEqualTo(personaAgr);

        // la persona quedo con el nombre mas reciente y conserva el telefono
        mvc.perform(get("/api/v1/personas/documento/DNI/" + dni).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombres").value("Kevin Quispe"))
                .andExpect(jsonPath("$.telefono").value("999111222"));
    }

    @Test
    void agricultor_duplicado_responde409() throws Exception {
        crear("/api/v1/agricultores", identidad(dni, "Kevin", null));

        mvc.perform(json(post("/api/v1/agricultores"), identidad(dni, "Kevin", null)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value(containsString("ya esta registrada como agricultor")));
    }

    @Test
    void agricultor_dniInvalido_responde400EnNumeroDocumento() throws Exception {
        mvc.perform(json(post("/api/v1/agricultores"), identidad("123", "Kevin", null)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors[0].field").value("numeroDocumento"));
    }

    @Test
    void agricultor_buscar_actualizar_desactivar_reactivar() throws Exception {
        String id = JsonPath.read(crear("/api/v1/agricultores", identidad(dni, "Kevin", null)), "$.id");

        mvc.perform(get("/api/v1/agricultores").header(TenantContext.HEADER, empresa).param("q", dni.substring(0, 5)))
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].persona.numeroDocumento").value(dni));
        mvc.perform(get("/api/v1/agricultores").header(TenantContext.HEADER, empresa).param("q", "kev"))
                .andExpect(jsonPath("$.totalElements").value(1));

        mvc.perform(json(put("/api/v1/agricultores/" + id), identidad(dni, "Kevin Arely", "987654321")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.persona.nombres").value("Kevin Arely"));

        mvc.perform(delete("/api/v1/agricultores/" + id).header(TenantContext.HEADER, empresa))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/agricultores").header(TenantContext.HEADER, empresa).param("activo", "true"))
                .andExpect(jsonPath("$.totalElements").value(0));
        mvc.perform(patch("/api/v1/agricultores/" + id + "/activar").header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$.activo").value(true));

        // aislamiento por empresa
        mvc.perform(get("/api/v1/agricultores/" + id).header(TenantContext.HEADER, otraEmpresa))
                .andExpect(status().isNotFound());
    }

    @Test
    void actualizar_conDocumentoDeOtraPersona_responde409() throws Exception {
        String otroDni = String.valueOf(Integer.parseInt(dni) + 1);
        crear("/api/v1/personas", identidad(otroDni, "Otra", null));
        String id = JsonPath.read(crear("/api/v1/agricultores", identidad(dni, "Kevin", null)), "$.id");

        mvc.perform(json(put("/api/v1/agricultores/" + id), identidad(otroDni, "Kevin", null)))
                .andExpect(status().isConflict());
    }

    @Test
    void persona_crud_yNoSePuedeEliminarSiEstaEnUso() throws Exception {
        String libre = JsonPath.read(crear("/api/v1/personas", identidad(dni, "Libre", null)), "$.id");
        mvc.perform(json(post("/api/v1/personas"), identidad(dni, "Libre", null)))
                .andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/personas/" + libre).header(TenantContext.HEADER, empresa))
                .andExpect(status().isNoContent());

        String agricultor = crear("/api/v1/agricultores", identidad(dni, "En uso", null));
        String personaEnUso = JsonPath.read(agricultor, "$.persona.id");
        mvc.perform(delete("/api/v1/personas/" + personaEnUso).header(TenantContext.HEADER, empresa))
                .andExpect(status().isUnprocessableContent());
    }

    @Test
    void persona_porDocumentoInexistente_responde404() throws Exception {
        mvc.perform(get("/api/v1/personas/documento/DNI/" + dni).header(TenantContext.HEADER, empresa))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Persona con DNI " + dni + " no existe"));
    }

    private String crear(String url, String body) throws Exception {
        return mvc.perform(json(post(url), body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
    }

    private MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder req, String body) {
        return json(req, empresa, body);
    }

    private static String identidad(String dni, String nombres, String telefono) {
        return """
                {"tipoDocumento":"DNI","numeroDocumento":"%s","nombres":"%s","telefono":%s}"""
                .formatted(dni, nombres, telefono == null ? "null" : "\"" + telefono + "\"");
    }
}
