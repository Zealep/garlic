package com.zealep.garlicbackend.catalogo;

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
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * CRUD completo de todos los catalogos contra Postgres real (Flyway + restricciones de la base).
 * Cada test usa empresas nuevas, asi los datos de un test no afectan a otro.
 */
class CatalogoCrudIT extends AbstractIntegrationTest {

    private static final String BASE = "/api/v1/catalogos/";

    private String empresaA;
    private String empresaB;
    private String cultivoAjo;

    @BeforeEach
    void setUp() {
        empresaA = nuevaEmpresa();
        empresaB = nuevaEmpresa();
        cultivoAjo = cultivoAjo();
    }

    /**
     * recurso, body de creacion, body de actualizacion, campo a verificar y valor esperado tras actualizar.
     * Placeholders: {CULTIVO} y {COD}.
     */
    static Stream<Arguments> catalogos() {
        String simple = """
                {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"Nombre {COD}","orden":1}""";
        String simpleUpd = """
                {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"Actualizado","orden":2}""";
        return Stream.of(
                Arguments.of("variedades", simple, simpleUpd, "$.nombre", "Actualizado"),
                Arguments.of("tipos-compra", simple, simpleUpd, "$.nombre", "Actualizado"),
                Arguments.of("clases-calidad", simple, simpleUpd, "$.nombre", "Actualizado"),
                Arguments.of("tipos-humedad", simple, simpleUpd, "$.nombre", "Actualizado"),
                Arguments.of("tipos-empaste", simple, simpleUpd, "$.nombre", "Actualizado"),
                Arguments.of("calibres",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"45/50","diametroMinMm":45,"diametroMaxMm":50}""",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"45/50","diametroMinMm":45,"diametroMaxMm":55.5}""",
                        "$.diametroMaxMm", 55.5),
                Arguments.of("tipos-dano",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"No contiene","esExcluyente":false}""",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"No contiene","esExcluyente":true}""",
                        "$.esExcluyente", true),
                Arguments.of("enfermedades",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"Fusarium","evaluarEnCampo":false}""",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","nombre":"Fusarium","nombreCientifico":"Fusarium spp.","evaluarEnCampo":true}""",
                        "$.evaluarEnCampo", true),
                Arguments.of("localidades",
                        """
                        {"nombre":"El {COD}","tipo":"CCPP"}""",
                        """
                        {"nombre":"El {COD}","tipo":"CIUDAD","ubigeo":"040129"}""",
                        "$.tipo", "CIUDAD"),
                Arguments.of("campanias",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","fechaInicio":"2026-01-01"}""",
                        """
                        {"cultivoId":"{CULTIVO}","codigo":"{COD}","fechaInicio":"2026-01-01","fechaFin":"2026-12-31"}""",
                        "$.fechaFin", "2026-12-31"));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("catalogos")
    void crudCompleto(String recurso, String crearTpl, String actualizarTpl, String campo, Object esperado) throws Exception {
        String url = BASE + recurso;
        String cod = "T" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        String crear = render(crearTpl, cod);

        // Crear
        String body = mvc.perform(json(post(url), empresaA, crear))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.activo").value(true))
                .andReturn().getResponse().getContentAsString();
        String id = JsonPath.read(body, "$.id");

        // Obtener y buscar
        mvc.perform(get(url + "/" + id).header(TenantContext.HEADER, empresaA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id));
        mvc.perform(get(url).header(TenantContext.HEADER, empresaA).param("q", cod.toLowerCase()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1));

        // Actualizar
        mvc.perform(json(put(url + "/" + id), empresaA, render(actualizarTpl, cod)))
                .andExpect(status().isOk())
                .andExpect(jsonPath(campo).value(esperado));

        // Duplicado -> 409 (restriccion UNIQUE de la base)
        mvc.perform(json(post(url), empresaA, crear))
                .andExpect(status().isConflict());

        // Aislamiento por empresa
        mvc.perform(get(url + "/" + id).header(TenantContext.HEADER, empresaB))
                .andExpect(status().isNotFound());
        mvc.perform(get(url).header(TenantContext.HEADER, empresaB))
                .andExpect(jsonPath("$.totalElements").value(0));
        // la otra empresa si puede usar el mismo codigo
        mvc.perform(json(post(url), empresaB, crear))
                .andExpect(status().isCreated());

        // Baja logica y reactivacion
        mvc.perform(delete(url + "/" + id).header(TenantContext.HEADER, empresaA))
                .andExpect(status().isNoContent());
        mvc.perform(get(url).header(TenantContext.HEADER, empresaA).param("activo", "true"))
                .andExpect(jsonPath("$.totalElements").value(0));
        mvc.perform(get(url + "/" + id).header(TenantContext.HEADER, empresaA))
                .andExpect(jsonPath("$.activo").value(false));
        mvc.perform(patch(url + "/" + id + "/activar").header(TenantContext.HEADER, empresaA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(true));
    }

    @Test
    void crear_conCultivoInexistente_responde422() throws Exception {
        String body = """
                {"cultivoId":"%s","codigo":"X1","nombre":"X"}""".formatted(UUID.randomUUID());

        mvc.perform(json(post(BASE + "variedades"), empresaA, body))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.title").value("Referencia invalida"));
    }

    @Test
    void crear_calibreConRangoInvalido_responde422() throws Exception {
        String body = """
                {"cultivoId":"%s","codigo":"X","nombre":"X","diametroMinMm":50,"diametroMaxMm":45}""".formatted(cultivoAjo);

        mvc.perform(json(post(BASE + "calibres"), empresaA, body))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.title").value("Regla de negocio"));
    }

    @Test
    void listar_ordenamientoInvalido_responde400() throws Exception {
        mvc.perform(get(BASE + "variedades").header(TenantContext.HEADER, empresaA).param("sort", "noExiste"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void cultivos_listaElCultivoBase() throws Exception {
        mvc.perform(get(BASE + "cultivos").header(TenantContext.HEADER, empresaA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.codigo == 'AJO')]").exists());
    }

    private String render(String template, String cod) {
        return template.replace("{CULTIVO}", cultivoAjo).replace("{COD}", cod);
    }


}
