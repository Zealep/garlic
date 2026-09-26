package com.zealep.garlicbackend.lote;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
import org.springframework.test.web.servlet.ResultActions;

/**
 * Punto 1 del protocolo (identificacion del lote) contra Postgres real.
 */
class LoteIT extends AbstractIntegrationTest {

    private static final String URL = "/api/v1/lotes";

    private String empresa;
    private String cultivo;
    private String campania;
    private String variedad;
    private String localidad;
    private String tipoCompra;
    private String agricultor;
    private String proveedor;

    @BeforeEach
    void setUp() throws Exception {
        empresa = nuevaEmpresa();
        cultivo = cultivoAjo();
        campania = crearId("/api/v1/catalogos/campanias", """
                {"cultivoId":"%s","codigo":"2025"}""".formatted(cultivo));
        variedad = crearCatalogo("variedades", "NAPURI");
        tipoCompra = crearCatalogo("tipos-compra", "PRIMERA_5_ARRIBA");
        localidad = crearId("/api/v1/catalogos/localidades", """
                {"nombre":"El Pedregal","tipo":"CCPP"}""");
        agricultor = crearId("/api/v1/agricultores", identidad(dni(), "Kevin"));
        proveedor = crearId("/api/v1/proveedores", identidad(dni(), "Neiver Lazarte"));
    }

    @Test
    void registrar_loteCompleto_conTitularDeLiquidacion() throws Exception {
        String dniLc = dni();
        String body = lote("LOTE 004", "B3 P52", campania, """
                "proveedorId":"%s","titularLiquidacion":{"tipoDocumento":"DNI","numeroDocumento":"%s","nombres":"Delgado Fernandez Judith"},
                "latitud":-16.345678,"longitud":-72.123456,"mapsUrl":"https://maps.app.goo.gl/x",
                "fechaArrancado":"2025-10-10","fechaCorte":"2025-10-12","fechaCarga":"2025-10-14",""".formatted(proveedor, dniLc));

        String id = JsonPath.read(crear(body).andReturn().getResponse().getContentAsString(), "$.id");

        mvc.perform(get(URL + "/" + id).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.codigo").value("LOTE 004"))
                .andExpect(jsonPath("$.estado").value("ACTIVO"))
                .andExpect(jsonPath("$.cultivoId").value(cultivo))
                .andExpect(jsonPath("$.campania.codigo").value("2025"))
                .andExpect(jsonPath("$.variedad.codigo").value("NAPURI"))
                .andExpect(jsonPath("$.agricultor.id").value(agricultor))
                .andExpect(jsonPath("$.agricultor.nombres").value("Kevin"))
                .andExpect(jsonPath("$.proveedor.nombres").value("Neiver Lazarte"))
                .andExpect(jsonPath("$.titularLiquidacion.numeroDocumento").value(dniLc))
                .andExpect(jsonPath("$.localidad.nombre").value("EL PEDREGAL"))
                .andExpect(jsonPath("$.zona").value("B3 P52"))
                .andExpect(jsonPath("$.latitud").value(-16.345678))
                .andExpect(jsonPath("$.tipoCompra.codigo").value("PRIMERA_5_ARRIBA"))
                .andExpect(jsonPath("$.fechaCarga").value("2025-10-14"));
    }

    @Test
    void zonaRepetida_enLaMismaCampania_responde409_aunqueCambieEspaciosYMayusculas() throws Exception {
        crear(lote("LOTE 001", "B3 P52", campania, ""));

        mvc.perform(json(post(URL), empresa, lote("LOTE 002", "  b3   p52 ", campania, "")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value(containsString("Ya existe el lote LOTE 001 en la zona B3 P52")));
    }

    @Test
    void mismaZona_enOtraCampania_estaPermitida() throws Exception {
        String campania2026 = crearId("/api/v1/catalogos/campanias", """
                {"cultivoId":"%s","codigo":"2026"}""".formatted(cultivo));
        crear(lote("LOTE 001", "B3 P52", campania, ""));

        crear(lote("LOTE 001", "B3 P52", campania2026, ""));
    }

    @Test
    void anular_liberaLaZona_yBloqueaCambios() throws Exception {
        String id = JsonPath.read(crear(lote("LOTE 001", "B3 P52", campania, "")).andReturn().getResponse().getContentAsString(), "$.id");

        mvc.perform(post(URL + "/" + id + "/anular").header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("ANULADO"));

        crear(lote("LOTE 002", "B3 P52", campania, ""));

        mvc.perform(post(URL + "/" + id + "/anular").header(TenantContext.HEADER, empresa))
                .andExpect(status().isConflict());
        mvc.perform(json(put(URL + "/" + id), empresa, lote("LOTE 001", "B9 P99", campania, "")))
                .andExpect(status().isConflict());
    }

    @Test
    void actualizar_conservaSuPropiaZona_yValidaLaDeOtros() throws Exception {
        String id = JsonPath.read(crear(lote("LOTE 001", "B3 P52", campania, "")).andReturn().getResponse().getContentAsString(), "$.id");
        crear(lote("LOTE 002", "B4 P10", campania, ""));

        mvc.perform(json(put(URL + "/" + id), empresa, lote("LOTE 001", "B3 P52", campania, "\"fechaCarga\":\"2025-11-01\",")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fechaCarga").value("2025-11-01"));
        mvc.perform(json(put(URL + "/" + id), empresa, lote("LOTE 001", "B4 P10", campania, "")))
                .andExpect(status().isConflict());
    }

    @Test
    void crear_conIdDelCliente_esIdempotente() throws Exception {
        String id = java.util.UUID.randomUUID().toString();
        String body = lote("LOTE 001", "B3 P52", campania, "\"id\":\"" + id + "\",");

        crear(body).andExpect(jsonPath("$.id").value(id));
        // reintento de sincronizacion: mismo id -> 200 con el existente, sin 409 por zona
        mvc.perform(json(post(URL), empresa, body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id));
        mvc.perform(get(URL).header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void codigoRepetido_enLaCampania_responde409() throws Exception {
        crear(lote("LOTE 001", "B3 P52", campania, ""));

        mvc.perform(json(post(URL), empresa, lote("lote 001", "B9 P99", campania, "")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value(containsString("codigo LOTE 001")));
    }

    @Test
    void referenciaInactivaODeOtraEmpresa_responde422() throws Exception {
        mvc.perform(delete("/api/v1/catalogos/variedades/" + variedad).header(TenantContext.HEADER, empresa))
                .andExpect(status().isNoContent());
        mvc.perform(json(post(URL), empresa, lote("LOTE 001", "B3 P52", campania, "")))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.detail").value(containsString("Variedad")));

        String otraEmpresa = nuevaEmpresa();
        mvc.perform(json(post(URL), otraEmpresa, lote("LOTE 001", "B3 P52", campania, "")))
                .andExpect(status().isUnprocessableContent());
    }

    @Test
    void datosInvalidos_responde400() throws Exception {
        mvc.perform(json(post(URL), empresa, lote("", "B3 P52", campania, "\"latitud\":123,")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.length()").value(2));
    }

    @Test
    void listar_filtra_yAislaPorEmpresa() throws Exception {
        String id = JsonPath.read(crear(lote("LOTE 001", "B3 P52", campania, "")).andReturn().getResponse().getContentAsString(), "$.id");
        crear(lote("LOTE 002", "B4 P10", campania, ""));

        mvc.perform(get(URL).header(TenantContext.HEADER, empresa).param("q", "b4"))
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].codigo").value("LOTE 002"));
        mvc.perform(get(URL).header(TenantContext.HEADER, empresa).param("q", "kevin").param("campaniaId", campania))
                .andExpect(jsonPath("$.totalElements").value(2));
        mvc.perform(get(URL).header(TenantContext.HEADER, empresa).param("estado", "ANULADO"))
                .andExpect(jsonPath("$.totalElements").value(0));

        String otraEmpresa = nuevaEmpresa();
        mvc.perform(get(URL + "/" + id).header(TenantContext.HEADER, otraEmpresa))
                .andExpect(status().isNotFound());
        mvc.perform(get(URL).header(TenantContext.HEADER, otraEmpresa))
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    // ---------------------------------------------------------------- helpers

    /** Body de lote con los campos obligatorios; {@code extra} agrega campos (terminados en coma). */
    private String lote(String codigo, String zona, String campaniaId, String extra) {
        return """
                {%s"campaniaId":"%s","codigo":"%s","variedadId":"%s","agricultorId":"%s",
                 "localidadId":"%s","zona":"%s","tipoCompraId":"%s"}"""
                .formatted(extra, campaniaId, codigo, variedad, agricultor, localidad, zona, tipoCompra);
    }

    private ResultActions crear(String body) throws Exception {
        return mvc.perform(json(post(URL), empresa, body)).andExpect(status().isCreated());
    }

    private String crearCatalogo(String recurso, String codigo) throws Exception {
        return crearId("/api/v1/catalogos/" + recurso, """
                {"cultivoId":"%s","codigo":"%s","nombre":"%s"}""".formatted(cultivo, codigo, codigo));
    }

    private String crearId(String url, String body) throws Exception {
        String res = mvc.perform(json(post(url), empresa, body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.id");
    }

    private static String identidad(String dni, String nombres) {
        return """
                {"tipoDocumento":"DNI","numeroDocumento":"%s","nombres":"%s"}""".formatted(dni, nombres);
    }

    private static String dni() {
        return String.valueOf(ThreadLocalRandom.current().nextInt(10_000_000, 99_999_999));
    }
}
