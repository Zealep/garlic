package com.zealep.garlicbackend.evaluacion;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.zealep.garlicbackend.shared.tenant.TenantContext;
import com.zealep.garlicbackend.support.AbstractIntegrationTest;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.RequestBuilder;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.json.JsonMapper;

/**
 * Punto 2 del protocolo contra Postgres real, usando el lote modelo del Excel
 * (3 muestras, PRIMERA 80/85/75 -> PROM 80; calibre 45/50 13/10/20 -> PROM 14.33).
 */
class EvaluacionIT extends AbstractIntegrationTest {

    private static final JsonMapper JSON = JsonMapper.builder().build();
    private static final byte[] FOTO = {(byte) 0x89, 'P', 'N', 'G', 1, 2, 3};

    private String empresa;
    private String cultivo;
    private String lote;
    private String evaluador;
    private String primera;
    private String abiertos;
    private String cal4550;
    private String cal5055;
    private String gotasDentro;
    private String rosaBeige;
    private String empasteBueno;
    private String noContiene;
    private String cerosa;
    private String raizRosada;
    private String fusarium;

    @BeforeEach
    void setUp() throws Exception {
        empresa = nuevaEmpresa();
        cultivo = cultivoAjo();
        primera = catalogo("clases-calidad", "PRIMERA", 1, "");
        abiertos = catalogo("clases-calidad", "ABIERTOS", 2, "");
        cal4550 = catalogo("calibres", "45/50", 1, ",\"diametroMinMm\":45,\"diametroMaxMm\":50");
        cal5055 = catalogo("calibres", "50/55", 2, ",\"diametroMinMm\":50,\"diametroMaxMm\":55");
        gotasDentro = catalogo("tipos-humedad", "GOTAS_DENTRO", 1, "");
        rosaBeige = catalogo("tipos-humedad", "ROSA_BEIGE", 2, "");
        empasteBueno = catalogo("tipos-empaste", "BUENO", 1, "");
        cerosa = catalogo("tipos-dano", "PARALISIS_CEROSA", 1, "");
        noContiene = catalogo("tipos-dano", "NO_CONTIENE", 3, ",\"esExcluyente\":true");
        raizRosada = catalogo("enfermedades", "RAIZ_ROSADA", 1, ",\"evaluarEnCampo\":true");
        fusarium = catalogo("enfermedades", "FUSARIUM", 2, ",\"evaluarEnCampo\":true");
        catalogo("enfermedades", "OXIDO", 3, "");

        evaluador = crearId("/api/v1/usuarios", """
                {"nombres":"Evaluador Uno","email":"eval-%s@demo.pe","rol":"EVALUADOR"}""".formatted(UUID.randomUUID()));
        lote = crearLote("B3 P52");
    }

    @Test
    void formulario_traeLasOpcionesActivasDelCultivo() throws Exception {
        mvc.perform(get("/api/v1/evaluaciones/formulario").header(TenantContext.HEADER, empresa).param("cultivoId", cultivo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.clasesCalidad", hasSize(2)))
                .andExpect(jsonPath("$.clasesCalidad[0].codigo").value("PRIMERA"))
                .andExpect(jsonPath("$.calibres", hasSize(2)))
                .andExpect(jsonPath("$.nivelesHumedad", hasSize(3)))
                .andExpect(jsonPath("$.tiposDano[1].esExcluyente").value(true))
                // solo las enfermedades a evaluar en campo (no OXIDO)
                .andExpect(jsonPath("$.enfermedades", hasSize(2)));
    }

    @Test
    void crear_loteModeloDelExcel_calculaPromedios_yCoincideConLasVistas() throws Exception {
        String res = crearEvaluacion(evaluacionModelo()).andReturn().getResponse().getContentAsString();
        String id = JsonPath.read(res, "$.id");

        mvc.perform(get("/api/v1/evaluaciones/" + id).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("BORRADOR"))
                .andExpect(jsonPath("$.loteCodigo").value("LOTE 004"))
                .andExpect(jsonPath("$.evaluador.nombres").value("Evaluador Uno"))
                .andExpect(jsonPath("$.muestras", hasSize(3)))
                .andExpect(jsonPath("$.muestras[0].calidad[0].codigo").value("PRIMERA"))
                .andExpect(jsonPath("$.promedios.calidad[0].codigo").value("PRIMERA"))
                .andExpect(jsonPath("$.promedios.calidad[0].porcentaje").value(80.00))
                .andExpect(jsonPath("$.promedios.calidad[1].porcentaje").value(20.00))
                .andExpect(jsonPath("$.promedios.calibres[0].codigo").value("45/50"))
                .andExpect(jsonPath("$.promedios.calibres[0].porcentaje").value(14.33))
                .andExpect(jsonPath("$.humedad", hasSize(2)))
                .andExpect(jsonPath("$.humedad[0].nivel").value("ALTA"))
                .andExpect(jsonPath("$.humedad[1].nivel").value("MEDIA"))
                .andExpect(jsonPath("$.empastes[0].codigo").value("BUENO"))
                .andExpect(jsonPath("$.danos[0].codigo").value("NO_CONTIENE"))
                .andExpect(jsonPath("$.sanidad[1].codigo").value("FUSARIUM"))
                .andExpect(jsonPath("$.sanidad[1].porcentaje").value(5.00));

        // la vista de la base (reportes) da el mismo PROM que el API
        BigDecimal promPrimera = jdbc.sql("""
                        SELECT porcentaje_promedio FROM v_evaluacion_calidad_prom
                        WHERE evaluacion_id = :id AND clase_calidad_codigo = 'PRIMERA'""")
                .param("id", UUID.fromString(id)).query(BigDecimal.class).single();
        assertThat(promPrimera).isEqualByComparingTo("80.00");

        mvc.perform(get("/api/v1/lotes/" + lote + "/evaluaciones").header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nroMuestras").value(3));
    }

    @Test
    void actualizar_reemplazaContenido_yConservaLasMuestrasQueSiguen() throws Exception {
        String res = crearEvaluacion(evaluacionModelo()).andReturn().getResponse().getContentAsString();
        String id = JsonPath.read(res, "$.id");
        String idMuestra1 = JsonPath.read(res, "$.muestras[0].id");

        Map<String, Object> cambio = evaluacionModelo();
        List<Map<String, Object>> muestras = muestras(cambio);
        muestras.remove(2);                                   // se quita la muestra 3
        muestras.get(0).put("calidad", calidad("90", "10"));  // se corrige la muestra 1
        cambio.put("danos", List.of(cerosa));
        cambio.put("humedad", List.of());

        mvc.perform(json(put("/api/v1/evaluaciones/" + id), empresa, JSON.writeValueAsString(cambio)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.muestras", hasSize(2)))
                .andExpect(jsonPath("$.muestras[0].id").value(idMuestra1))
                .andExpect(jsonPath("$.promedios.calidad[0].porcentaje").value(87.50))
                .andExpect(jsonPath("$.humedad", hasSize(0)))
                .andExpect(jsonPath("$.danos[0].codigo").value("PARALISIS_CEROSA"));

        long filasMuestra = jdbc.sql("SELECT count(*) FROM muestra WHERE evaluacion_id = :id")
                .param("id", UUID.fromString(id)).query(Long.class).single();
        assertThat(filasMuestra).isEqualTo(2);
    }

    @Test
    void sincronizacionOffline_crearCerrarYSubirFoto_sonIdempotentes() throws Exception {
        String id = UUID.randomUUID().toString();
        Map<String, Object> body = evaluacionModelo();
        body.put("id", id);

        crearEvaluacion(body).andExpect(jsonPath("$.id").value(id));
        mvc.perform(json(post("/api/v1/lotes/" + lote + "/evaluaciones"), empresa, JSON.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id));

        String evidenciaId = UUID.randomUUID().toString();
        mvc.perform(multipart("/api/v1/evaluaciones/" + id + "/evidencias")
                        .file(new MockMultipartFile("archivo", "foto", "image/png", FOTO))
                        .param("id", evidenciaId).header(TenantContext.HEADER, empresa))
                .andExpect(status().isCreated());
        mvc.perform(multipart("/api/v1/evaluaciones/" + id + "/evidencias")
                        .file(new MockMultipartFile("archivo", "foto", "image/png", FOTO))
                        .param("id", evidenciaId).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(evidenciaId));

        for (int i = 0; i < 2; i++) {
            mvc.perform(post("/api/v1/evaluaciones/" + id + "/cerrar").header(TenantContext.HEADER, empresa))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.estado").value("CERRADA"));
        }
        mvc.perform(get("/api/v1/evaluaciones/" + id + "/evidencias").header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$", hasSize(1)));
    }

    @Test
    void bandeja_filtraPorEstado() throws Exception {
        crearEvaluacion(evaluacionModelo());
        String cerrada = JsonPath.read(crearEvaluacion(evaluacionModelo()).andReturn().getResponse().getContentAsString(), "$.id");
        mvc.perform(post("/api/v1/evaluaciones/" + cerrada + "/cerrar").header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/evaluaciones").header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.content[0].loteCodigo").value("LOTE 004"))
                .andExpect(jsonPath("$.content[0].zona").value("B3 P52"))
                .andExpect(jsonPath("$.content[0].nroMuestras").value(3));
        mvc.perform(get("/api/v1/evaluaciones").header(TenantContext.HEADER, empresa).param("estado", "CERRADA"))
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].id").value(cerrada));
        mvc.perform(get("/api/v1/evaluaciones").header(TenantContext.HEADER, nuevaEmpresa()))
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void reglasDeNegocio_responden422() throws Exception {
        Map<String, Object> mala = evaluacionModelo();
        muestras(mala).get(0).put("calidad", calidad("80", "10"));
        crearEvaluacionEsperando(mala, 422, "la calidad debe sumar 100%");

        Map<String, Object> excluyente = evaluacionModelo();
        excluyente.put("danos", List.of(noContiene, cerosa));
        crearEvaluacionEsperando(excluyente, 422, "no puede marcarse junto a otros danos");

        Map<String, Object> otraEmpresa = evaluacionModelo();
        otraEmpresa.put("empastes", List.of(UUID.randomUUID()));
        crearEvaluacionEsperando(otraEmpresa, 422, "Tipo de empaste no existe o esta inactivo");
    }

    @Test
    void datosInvalidos_responden400() throws Exception {
        Map<String, Object> mala = evaluacionModelo();
        muestras(mala).get(0).put("calidad", calidad("120", "-20"));

        mvc.perform(json(post("/api/v1/lotes/" + lote + "/evaluaciones"), empresa, JSON.writeValueAsString(mala)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors", hasSize(2)));
    }

    @Test
    void cerrar_exigeEvaluacionCompleta_yLuegoNoSePuedeModificar() throws Exception {
        Map<String, Object> incompleta = evaluacionModelo();
        incompleta.put("sanidad", List.of(sanidad(raizRosada, false, null)));
        String id = JsonPath.read(crearEvaluacion(incompleta).andReturn().getResponse().getContentAsString(), "$.id");

        mvc.perform(post("/api/v1/evaluaciones/" + id + "/cerrar").header(TenantContext.HEADER, empresa))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.detail").value(containsString("responda SI/NO")));

        mvc.perform(json(put("/api/v1/evaluaciones/" + id), empresa, JSON.writeValueAsString(evaluacionModelo())))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/evaluaciones/" + id + "/cerrar").header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("CERRADA"));

        mvc.perform(json(put("/api/v1/evaluaciones/" + id), empresa, JSON.writeValueAsString(evaluacionModelo())))
                .andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/evaluaciones/" + id).header(TenantContext.HEADER, empresa))
                .andExpect(status().isConflict());
        mvc.perform(subirFoto(id, "1", "image/png"))
                .andExpect(status().isConflict());
    }

    @Test
    void loteAnulado_noSePuedeEvaluar() throws Exception {
        mvc.perform(post("/api/v1/lotes/" + lote + "/anular").header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk());

        crearEvaluacionEsperando(evaluacionModelo(), 422, "no existe o esta anulado");
    }

    @Test
    void evidencias_subir_descargar_yEliminarseConSuMuestra() throws Exception {
        String id = JsonPath.read(crearEvaluacion(evaluacionModelo()).andReturn().getResponse().getContentAsString(), "$.id");

        String subida = mvc.perform(subirFoto(id, "3", "image/png"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.muestraNumero").value(3))
                .andExpect(jsonPath("$.factor").value("CALIDAD"))
                .andReturn().getResponse().getContentAsString();
        String url = JsonPath.read(subida, "$.url");
        mvc.perform(subirFoto(id, null, "image/jpeg")).andExpect(status().isCreated());   // evidencia general

        mvc.perform(get(url).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/png"))
                .andExpect(content().bytes(FOTO));
        mvc.perform(get("/api/v1/evaluaciones/" + id + "/evidencias").header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$", hasSize(2)));

        // validaciones de la subida
        mvc.perform(subirFoto(id, "9", "image/png")).andExpect(status().isUnprocessableContent());
        mvc.perform(subirFoto(id, "1", "text/plain")).andExpect(status().isUnprocessableContent());
        mvc.perform(get(url).header(TenantContext.HEADER, nuevaEmpresa())).andExpect(status().isNotFound());

        // al quitar la muestra 3 se eliminan sus fotos (registro y archivo)
        String clave = jdbc.sql("SELECT url_archivo FROM evidencia WHERE evaluacion_id = :id AND muestra_id IS NOT NULL")
                .param("id", UUID.fromString(id)).query(String.class).single();
        Map<String, Object> sinMuestra3 = evaluacionModelo();
        muestras(sinMuestra3).remove(2);
        mvc.perform(json(put("/api/v1/evaluaciones/" + id), empresa, JSON.writeValueAsString(sinMuestra3)))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/evaluaciones/" + id + "/evidencias").header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$", hasSize(1)));
        assertThat(Path.of("target/test-evidencias", clave)).doesNotExist();

        // eliminar el borrador elimina sus evidencias
        mvc.perform(delete("/api/v1/evaluaciones/" + id).header(TenantContext.HEADER, empresa))
                .andExpect(status().isNoContent());
        long evidencias = jdbc.sql("SELECT count(*) FROM evidencia WHERE evaluacion_id = :id")
                .param("id", UUID.fromString(id)).query(Long.class).single();
        assertThat(evidencias).isZero();
        assertThat(Files.exists(Path.of("target/test-evidencias", empresa, id))).isTrue(); // carpeta queda, vacia
        try (var archivos = Files.list(Path.of("target/test-evidencias", empresa, id))) {
            assertThat(archivos).isEmpty();
        }
    }

    // ---------------------------------------------------------------- datos

    /** Lote modelo del Excel: 3 muestras, humedad, empaste, danos y sanidad. */
    private Map<String, Object> evaluacionModelo() {
        Map<String, Object> ev = new LinkedHashMap<>();
        ev.put("evaluadorId", evaluador);
        ev.put("fechaEvaluacion", "2025-10-10");
        ev.put("observacion", "SE RECOMIENDA CARGAR EN 3 DIAS PARA BAJAR LA HUMEDAD");
        ev.put("muestras", new ArrayList<>(List.of(
                muestra(1, "80", "20", "13", "18.2"),
                muestra(2, "85", "15", "10", "15"),
                muestra(3, "75", "25", "20", "20"))));
        ev.put("humedad", List.of(
                Map.of("tipoHumedadId", gotasDentro, "nivel", "ALTA"),
                Map.of("tipoHumedadId", rosaBeige, "nivel", "MEDIA")));
        ev.put("empastes", List.of(empasteBueno));
        ev.put("danos", List.of(noContiene));
        ev.put("sanidad", List.of(sanidad(raizRosada, false, null), sanidad(fusarium, true, "5")));
        return ev;
    }

    private Map<String, Object> muestra(int numero, String primeraPct, String abiertosPct, String c4550, String c5055) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("numero", numero);
        m.put("calidad", calidad(primeraPct, abiertosPct));
        m.put("calibres", List.of(
                Map.of("calibreId", cal4550, "porcentaje", new BigDecimal(c4550)),
                Map.of("calibreId", cal5055, "porcentaje", new BigDecimal(c5055))));
        return m;
    }

    private List<Map<String, Object>> calidad(String primeraPct, String abiertosPct) {
        return List.of(
                Map.of("claseCalidadId", primera, "porcentaje", new BigDecimal(primeraPct)),
                Map.of("claseCalidadId", abiertos, "porcentaje", new BigDecimal(abiertosPct)));
    }

    private static Map<String, Object> sanidad(String enfermedadId, boolean presente, String pct) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("enfermedadId", enfermedadId);
        s.put("presente", presente);
        s.put("porcentaje", pct == null ? null : new BigDecimal(pct));
        return s;
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> muestras(Map<String, Object> ev) {
        return (List<Map<String, Object>>) ev.get("muestras");
    }

    // ---------------------------------------------------------------- helpers HTTP

    private ResultActions crearEvaluacion(Map<String, Object> body) throws Exception {
        return mvc.perform(json(post("/api/v1/lotes/" + lote + "/evaluaciones"), empresa, JSON.writeValueAsString(body)))
                .andExpect(status().isCreated());
    }

    private void crearEvaluacionEsperando(Map<String, Object> body, int status, String detalle) throws Exception {
        mvc.perform(json(post("/api/v1/lotes/" + lote + "/evaluaciones"), empresa, JSON.writeValueAsString(body)))
                .andExpect(status().is(status))
                .andExpect(jsonPath("$.detail").value(containsString(detalle)));
    }

    private RequestBuilder subirFoto(
            String evaluacionId, String muestraNumero, String tipo) {
        var req = multipart("/api/v1/evaluaciones/" + evaluacionId + "/evidencias")
                .file(new MockMultipartFile("archivo", "foto", tipo, FOTO))
                .param("factor", "CALIDAD")
                .header(TenantContext.HEADER, empresa);
        return muestraNumero == null ? req : req.param("muestraNumero", muestraNumero);
    }

    private String catalogo(String recurso, String codigo, int orden, String extra) throws Exception {
        return crearId("/api/v1/catalogos/" + recurso, """
                {"cultivoId":"%s","codigo":"%s","nombre":"%s","orden":%d%s}"""
                .formatted(cultivo, codigo, codigo.replace('_', ' '), orden, extra));
    }

    private String crearLote(String zona) throws Exception {
        String campania = crearId("/api/v1/catalogos/campanias", """
                {"cultivoId":"%s","codigo":"2025"}""".formatted(cultivo));
        String variedad = catalogo("variedades", "NAPURI", 1, "");
        String tipoCompra = catalogo("tipos-compra", "PRIMERA_5_ARRIBA", 1, "");
        String localidad = crearId("/api/v1/catalogos/localidades", """
                {"nombre":"El Pedregal","tipo":"CCPP"}""");
        String agricultor = crearId("/api/v1/agricultores", """
                {"tipoDocumento":"DNI","numeroDocumento":"%d","nombres":"Kevin"}"""
                .formatted(ThreadLocalRandom.current().nextInt(10_000_000, 99_999_999)));
        return crearId("/api/v1/lotes", """
                {"campaniaId":"%s","codigo":"LOTE 004","variedadId":"%s","agricultorId":"%s",
                 "localidadId":"%s","zona":"%s","tipoCompraId":"%s"}"""
                .formatted(campania, variedad, agricultor, localidad, zona, tipoCompra));
    }

    private String crearId(String url, String body) throws Exception {
        String res = mvc.perform(json(post(url), empresa, body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.id");
    }
}
