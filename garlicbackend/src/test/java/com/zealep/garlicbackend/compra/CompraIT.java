package com.zealep.garlicbackend.compra;

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
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Punto 3 contra Postgres real con el ejemplo del Excel: precios 3.4 / 1.4, llenado 0.30, pactado 2.80,
 * dos camiones de 15 000 kg con 1% de destare y gastos 1800 + 30 + 900 + 70.
 */
class CompraIT extends AbstractIntegrationTest {

    private static final byte[] FOTO = {(byte) 0x89, 'P', 'N', 'G', 1, 2, 3};

    private String empresa;
    private String cultivo;
    private String primera;
    private String abiertos;
    private String calibre;
    private String malla;
    private String estiba;
    private String pesaje;
    private String flete;
    private String otros;
    private String ctaBanco;
    private String lote;
    private String agricultorPersona;
    private String evaluacionCerrada;
    private int orden;

    @BeforeEach
    void setUp() throws Exception {
        empresa = nuevaEmpresa();
        cultivo = cultivoAjo();
        primera = catalogo("clases-calidad", "PRIMERA", "");
        abiertos = catalogo("clases-calidad", "ABIERTOS", "");
        calibre = catalogo("calibres", "45/50", "");
        malla = catalogo("tipos-empaque", "MALLA", ",\"pesoReferencialKg\":40");
        estiba = catalogo("tipos-gasto", "ESTIBA", ",\"porCarga\":true");
        pesaje = catalogo("tipos-gasto", "PESAJE", ",\"porCarga\":true");
        flete = catalogo("tipos-gasto", "FLETE", ",\"porCarga\":true");
        otros = catalogo("tipos-gasto", "OTROS", ",\"requiereDescripcion\":true");
        ctaBanco = catalogo("condiciones-pago", "CTA_BANCO", "");
        lote = crearLote();
        evaluacionCerrada = crearEvaluacion(true);
    }

    @Test
    void flujoCompleto_ejemploDelExcel() throws Exception {
        // 1. Fijacion de precio: promedio de muestras 3.00 - llenado 0.30 = tecnico 2.70; pactado 2.80
        mvc.perform(json(put(url("/fijacion-precio")), empresa, fijacion(evaluacionCerrada, "2.80")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.precioPromedio").value(3.0))
                .andExpect(jsonPath("$.precioTecnico").value(2.7))
                .andExpect(jsonPath("$.precioPactado").value(2.8))
                .andExpect(jsonPath("$.ajuste").value(0.1))
                .andExpect(jsonPath("$.preciosMuestra", hasSize(3)))
                .andExpect(jsonPath("$.preciosMuestra[1].precio").value(3.1))
                .andExpect(jsonPath("$.precios[0].codigo").value("PRIMERA"));
        // reemplazo: 200
        mvc.perform(json(put(url("/fijacion-precio")), empresa, fijacion(evaluacionCerrada, "2.80")))
                .andExpect(status().isOk());

        // 2. Dos camiones
        String carga1 = UUID.randomUUID().toString();
        String carga2 = UUID.randomUUID().toString();
        mvc.perform(json(put(url("/cargas/" + carga1)), empresa, carga("abc-123")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.placa").value("ABC-123"))
                .andExpect(jsonPath("$.tipoEmpaque").value("MALLA"))
                .andExpect(jsonPath("$.destareKg").value(150.0))
                .andExpect(jsonPath("$.kgNeto").value(14850.0))
                .andExpect(jsonPath("$.total").value(41580.0));
        mvc.perform(json(put(url("/cargas/" + carga2)), empresa, carga(null))).andExpect(status().isCreated());

        // 3. Gastos vinculados (por carga y uno general)
        gasto(carga1, estiba, "1800", null).andExpect(status().isCreated());
        gasto(carga1, pesaje, "30", null).andExpect(status().isCreated());
        gasto(carga2, flete, "900", null).andExpect(status().isCreated());
        gasto(null, otros, "70", "Viaticos").andExpect(status().isCreated())
                .andExpect(jsonPath("$.cargaId").doesNotExist());

        // 4. Pago parcial
        String pago = UUID.randomUUID().toString();
        mvc.perform(json(put(url("/pagos/" + pago)), empresa, pago("50000", agricultorPersona)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.condicionPago").value("CTA BANCO"))
                .andExpect(jsonPath("$.beneficiario").value("Kevin"));

        // 5. Balance
        mvc.perform(get(url("/compra")).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fijacion.precioPactado").value(2.8))
                .andExpect(jsonPath("$.cargas", hasSize(2)))
                .andExpect(jsonPath("$.gastos", hasSize(4)))
                .andExpect(jsonPath("$.pagos", hasSize(1)))
                .andExpect(jsonPath("$.resumen.nroCargas").value(2))
                .andExpect(jsonPath("$.resumen.cantidadEmpaques").value(750))
                .andExpect(jsonPath("$.resumen.kgNetos").value(29700.0))
                .andExpect(jsonPath("$.resumen.totalMp").value(83160.0))
                .andExpect(jsonPath("$.resumen.totalPagado").value(50000.0))
                .andExpect(jsonPath("$.resumen.saldo").value(33160.0))
                .andExpect(jsonPath("$.resumen.estadoPago").value("PARCIAL"))
                .andExpect(jsonPath("$.resumen.gastosVinculados").value(2800.0))
                .andExpect(jsonPath("$.resumen.costoPacking").value(85960.0))
                .andExpect(jsonPath("$.resumen.cuMp").value(2.8))
                .andExpect(jsonPath("$.resumen.cuPacking").value(2.8943));
    }

    @Test
    void fijacion_exigeEvaluacionCerrada_yPrecioDeCadaClaseParaPactar() throws Exception {
        String borrador = crearEvaluacion(false);
        mvc.perform(json(put(url("/fijacion-precio")), empresa, fijacion(borrador, null)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.detail").value(containsString("evaluacion cerrada")));

        String soloPrimera = """
                {"evaluacionId":"%s","precios":[{"claseCalidadId":"%s","precioBase":3.4}],"gastoLlenado":0.3,
                 "precioPactado":%s}""";
        mvc.perform(json(put(url("/fijacion-precio")), empresa, soloPrimera.formatted(evaluacionCerrada, primera, "2.8")))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.detail").value(containsString("ABIERTOS")));

        // sin pactar todavia se puede guardar (calculo en borrador); ABIERTOS sin precio cuenta 0
        mvc.perform(json(put(url("/fijacion-precio")), empresa, soloPrimera.formatted(evaluacionCerrada, primera, "null")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.precioPromedio").value(2.72));
    }

    @Test
    void sincronizacionOffline_putEsIdempotente_yDeleteDevuelve404SiNoExiste() throws Exception {
        String id = UUID.randomUUID().toString();
        mvc.perform(json(put(url("/cargas/" + id)), empresa, carga(null))).andExpect(status().isCreated());
        mvc.perform(json(put(url("/cargas/" + id)), empresa, carga(null))).andExpect(status().isOk());
        long filas = jdbc.sql("SELECT count(*) FROM carga WHERE id = :id").param("id", UUID.fromString(id))
                .query(Long.class).single();
        assertThat(filas).isEqualTo(1);

        // carga con gastos no se elimina
        gasto(id, estiba, "100", null).andExpect(status().isCreated());
        mvc.perform(delete(url("/cargas/" + id)).header(TenantContext.HEADER, empresa)).andExpect(status().isConflict());

        String pago = UUID.randomUUID().toString();
        mvc.perform(json(put(url("/pagos/" + pago)), empresa, pago("100", null))).andExpect(status().isCreated());
        mvc.perform(delete(url("/pagos/" + pago)).header(TenantContext.HEADER, empresa)).andExpect(status().isNoContent());
        mvc.perform(delete(url("/pagos/" + pago)).header(TenantContext.HEADER, empresa)).andExpect(status().isNotFound());
    }

    @Test
    void validaciones() throws Exception {
        // gasto OTROS sin descripcion
        gasto(null, otros, "70", null).andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.detail").value(containsString("Describa")));
        // carga de otro lote / inexistente
        gasto(UUID.randomUUID().toString(), estiba, "70", null).andExpect(status().isUnprocessableContent());
        // monto 0 y destare > 100 -> 400
        mvc.perform(json(put(url("/pagos/" + UUID.randomUUID())), empresa, pago("0", null))).andExpect(status().isBadRequest());
        mvc.perform(json(put(url("/cargas/" + UUID.randomUUID())), empresa, """
                {"fecha":"2025-10-20","kg":100,"precioKg":2.8,"destarePct":150}""")).andExpect(status().isBadRequest());
        // otra empresa no ve el lote
        mvc.perform(get(url("/compra")).header(TenantContext.HEADER, nuevaEmpresa())).andExpect(status().isNotFound());
    }

    @Test
    void loteAnulado_noAceptaCambios() throws Exception {
        mvc.perform(post("/api/v1/lotes/" + lote + "/anular").header(TenantContext.HEADER, empresa)).andExpect(status().isOk());
        mvc.perform(json(put(url("/cargas/" + UUID.randomUUID())), empresa, carga(null))).andExpect(status().isConflict());
        mvc.perform(get(url("/compra")).header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resumen.estadoPago").value("SIN_COMPRAS"));
    }

    @Test
    void comprobantes_deCargaYPago_idempotentes_yBorradosConSuRegistro() throws Exception {
        String carga = UUID.randomUUID().toString();
        mvc.perform(json(put(url("/cargas/" + carga)), empresa, carga(null))).andExpect(status().isCreated());

        String foto = UUID.randomUUID().toString();
        subir(foto, "CARGA", carga).andExpect(status().isCreated()).andExpect(jsonPath("$.entidad").value("CARGA"));
        subir(foto, "CARGA", carga).andExpect(status().isOk());
        // registro que aun no se sincroniza
        subir(UUID.randomUUID().toString(), "PAGO", UUID.randomUUID().toString())
                .andExpect(status().isUnprocessableContent());

        mvc.perform(get("/api/v1/comprobantes/" + foto + "/archivo").header(TenantContext.HEADER, empresa))
                .andExpect(status().isOk())
                .andExpect(content().bytes(FOTO));
        mvc.perform(get(url("/compra")).header(TenantContext.HEADER, empresa))
                .andExpect(jsonPath("$.comprobantes", hasSize(1)));

        mvc.perform(delete(url("/cargas/" + carga)).header(TenantContext.HEADER, empresa)).andExpect(status().isNoContent());
        long fotos = jdbc.sql("SELECT count(*) FROM comprobante WHERE entidad_id = :id")
                .param("id", UUID.fromString(carga)).query(Long.class).single();
        assertThat(fotos).isZero();
    }

    // ---------------------------------------------------------------- datos

    private String fijacion(String evaluacionId, String pactado) {
        return """
                {"evaluacionId":"%s","precios":[{"claseCalidadId":"%s","precioBase":3.4},{"claseCalidadId":"%s","precioBase":1.4}],
                 "gastoLlenado":0.30,"precioPactado":%s,"fechaPacto":"2025-10-12"}"""
                .formatted(evaluacionId, primera, abiertos, pactado == null ? "null" : pactado);
    }

    private String carga(String placa) {
        return """
                {"fecha":"2025-10-20","placa":%s,"kg":15000,"cantidadEmpaques":375,"tipoEmpaqueId":"%s",
                 "precioKg":2.8,"destarePct":1}"""
                .formatted(placa == null ? "null" : "\"" + placa + "\"", malla);
    }

    private ResultActions gasto(String cargaId, String tipo, String monto, String descripcion) throws Exception {
        String body = """
                {"cargaId":%s,"tipoGastoId":"%s","fecha":"2025-10-20","monto":%s,"descripcion":%s}"""
                .formatted(cargaId == null ? "null" : "\"" + cargaId + "\"", tipo, monto,
                        descripcion == null ? "null" : "\"" + descripcion + "\"");
        return mvc.perform(json(put(url("/gastos/" + UUID.randomUUID())), empresa, body));
    }

    private String pago(String monto, String beneficiario) {
        return """
                {"fecha":"2025-10-21","condicionPagoId":"%s","monto":%s,"beneficiarioId":%s,"referencia":"OP-001"}"""
                .formatted(ctaBanco, monto, beneficiario == null ? "null" : "\"" + beneficiario + "\"");
    }

    private ResultActions subir(String id, String entidad, String entidadId) throws Exception {
        return mvc.perform(multipart(url("/comprobantes"))
                .file(new MockMultipartFile("archivo", "foto", "image/png", FOTO))
                .param("id", id).param("entidad", entidad).param("entidadId", entidadId)
                .header(TenantContext.HEADER, empresa));
    }

    private String url(String sufijo) {
        return "/api/v1/lotes/" + lote + sufijo;
    }

    // ---------------------------------------------------------------- lote y evaluacion

    /** Evaluacion del Excel: PRIMERA 80/85/75, ABIERTOS 20/15/25, un calibre al 100%. */
    private String crearEvaluacion(boolean cerrar) throws Exception {
        String evaluador = crearId("/api/v1/usuarios", """
                {"nombres":"Evaluador","email":"eval-%s@demo.pe","rol":"EVALUADOR"}""".formatted(UUID.randomUUID()));
        String body = """
                {"evaluadorId":"%s","fechaEvaluacion":"2025-10-10","muestras":[%s,%s,%s]}"""
                .formatted(evaluador, muestra(1, 80, 20), muestra(2, 85, 15), muestra(3, 75, 25));
        String id = crearId("/api/v1/lotes/" + lote + "/evaluaciones", body);
        if (cerrar) {
            mvc.perform(post("/api/v1/evaluaciones/" + id + "/cerrar").header(TenantContext.HEADER, empresa))
                    .andExpect(status().isOk());
        }
        return id;
    }

    private String muestra(int numero, int primeraPct, int abiertosPct) {
        return """
                {"numero":%d,"calidad":[{"claseCalidadId":"%s","porcentaje":%d},{"claseCalidadId":"%s","porcentaje":%d}],
                 "calibres":[{"calibreId":"%s","porcentaje":100}]}"""
                .formatted(numero, primera, primeraPct, abiertos, abiertosPct, calibre);
    }

    private String crearLote() throws Exception {
        String campania = crearId("/api/v1/catalogos/campanias", """
                {"cultivoId":"%s","codigo":"2025"}""".formatted(cultivo));
        String variedad = catalogo("variedades", "NAPURI", "");
        String tipoCompra = catalogo("tipos-compra", "PRIMERA_5_ARRIBA", "");
        String localidad = crearId("/api/v1/catalogos/localidades", """
                {"nombre":"El Pedregal","tipo":"CCPP"}""");
        String agricultorRes = mvc.perform(json(post("/api/v1/agricultores"), empresa, """
                        {"tipoDocumento":"DNI","numeroDocumento":"%d","nombres":"Kevin"}"""
                        .formatted(ThreadLocalRandom.current().nextInt(10_000_000, 99_999_999))))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String agricultor = JsonPath.read(agricultorRes, "$.id");
        agricultorPersona = JsonPath.read(agricultorRes, "$.persona.id");
        return crearId("/api/v1/lotes", """
                {"campaniaId":"%s","codigo":"LOTE 004","variedadId":"%s","agricultorId":"%s",
                 "localidadId":"%s","zona":"B3 P52","tipoCompraId":"%s"}"""
                .formatted(campania, variedad, agricultor, localidad, tipoCompra));
    }

    private String catalogo(String recurso, String codigo, String extra) throws Exception {
        return crearId("/api/v1/catalogos/" + recurso, """
                {"cultivoId":"%s","codigo":"%s","nombre":"%s","orden":%d%s}"""
                .formatted(cultivo, codigo, codigo.replace('_', ' '), ++orden, extra));
    }

    private String crearId(String url, String body) throws Exception {
        String res = mvc.perform(json(post(url), empresa, body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(res, "$.id");
    }
}
