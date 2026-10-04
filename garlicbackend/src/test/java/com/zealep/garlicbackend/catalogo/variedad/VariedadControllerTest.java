package com.zealep.garlicbackend.catalogo.variedad;

import static org.hamcrest.Matchers.endsWith;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.zealep.garlicbackend.catalogo.base.CatalogoFiltro;
import com.zealep.garlicbackend.shared.exception.NotFoundException;
import com.zealep.garlicbackend.shared.tenant.TenantContext;
import com.zealep.garlicbackend.shared.web.PageResponse;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import com.zealep.garlicbackend.shared.instalacion.Instalacion;

@WebMvcTest(VariedadController.class)
class VariedadControllerTest {

    private static final String URL = "/api/v1/catalogos/variedades";
    private static final String EMPRESA = UUID.randomUUID().toString();
    private static final UUID CULTIVO = UUID.randomUUID();

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private VariedadService service;

    /** Instalacion no dedicada (mock: dedicada() = false). */
    @MockitoBean
    private Instalacion instalacion;

    @Test
    void sinHeaderDeEmpresa_responde400() throws Exception {
        mvc.perform(get(URL))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Empresa no indicada"));
        verifyNoInteractions(service);
    }

    @Test
    void headerDeEmpresaInvalido_responde400() throws Exception {
        mvc.perform(get(URL).header(TenantContext.HEADER, "no-es-uuid"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void listar_devuelvePagina() throws Exception {
        when(service.listar(any(CatalogoFiltro.class), any(Pageable.class)))
                .thenReturn(new PageResponse<>(List.of(respuesta(UUID.randomUUID())), 0, 20, 1, 1));

        mvc.perform(get(URL).header(TenantContext.HEADER, EMPRESA).param("q", "napu").param("activo", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].codigo").value("NAPURI"))
                .andExpect(jsonPath("$.totalElements").value(1));

        verify(service).listar(eq(new CatalogoFiltro("napu", true, null)), any(Pageable.class));
    }

    @Test
    void crear_valido_responde201ConLocation() throws Exception {
        UUID id = UUID.randomUUID();
        when(service.crear(any(VariedadRequest.class))).thenReturn(respuesta(id));

        mvc.perform(post(URL).header(TenantContext.HEADER, EMPRESA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"cultivoId":"%s","codigo":"napuri","nombre":"Napuri","orden":3}
                                """.formatted(CULTIVO)))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", endsWith(URL + "/" + id)))
                .andExpect(jsonPath("$.id").value(id.toString()));
    }

    @Test
    void crear_invalido_responde400ConErroresPorCampo() throws Exception {
        mvc.perform(post(URL).header(TenantContext.HEADER, EMPRESA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"codigo":"","nombre":"Napuri","orden":-1}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Datos invalidos"))
                .andExpect(jsonPath("$.errors.length()").value(3));
        verifyNoInteractions(service);
    }

    @Test
    void crear_duplicado_responde409() throws Exception {
        when(service.crear(any(VariedadRequest.class))).thenThrow(new DataIntegrityViolationException("dup"));

        mvc.perform(post(URL).header(TenantContext.HEADER, EMPRESA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"cultivoId":"%s","codigo":"NAPURI","nombre":"Napuri"}
                                """.formatted(CULTIVO)))
                .andExpect(status().isConflict());
    }

    @Test
    void obtener_noExistente_responde404ProblemDetail() throws Exception {
        UUID id = UUID.randomUUID();
        when(service.obtener(id)).thenThrow(new NotFoundException("Variedad", id));

        mvc.perform(get(URL + "/" + id).header(TenantContext.HEADER, EMPRESA))
                .andExpect(status().isNotFound())
                .andExpect(header().string("Content-Type", "application/problem+json"))
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.detail").value("Variedad con id " + id + " no existe"));
    }

    @Test
    void desactivar_responde204() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(delete(URL + "/" + id).header(TenantContext.HEADER, EMPRESA))
                .andExpect(status().isNoContent());
        verify(service).desactivar(id);
    }

    private static VariedadResponse respuesta(UUID id) {
        return new VariedadResponse(id, CULTIVO, "NAPURI", "Napuri", (short) 3, true, Instant.now(), Instant.now());
    }
}
