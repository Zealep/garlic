package com.zealep.garlicbackend.acceso;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.zealep.garlicbackend.support.AbstractIntegrationTest;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Login con DNI + clave, refresh rotativo, cierre de sesion, cambio y restablecimiento de clave. */
class AccesoIT extends AbstractIntegrationTest {

    private static final String CLAVE = "clave-segura-1";

    @Autowired
    private PasswordEncoder encoder;

    private String empresa;
    private String dni;
    private String usuarioId;

    @BeforeEach
    void preparar() {
        empresa = nuevaEmpresa();
        dni = dniAlAzar();
        usuarioId = crearUsuario(dni, CLAVE, "EVALUADOR", true);
    }

    @Test
    void loginCorrecto_daTokens_yConElAccessTokenSeUsaElApi() throws Exception {
        String r = login(dni, CLAVE)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usuario.nombres").value("Usuario " + dni))
                .andExpect(jsonPath("$.usuario.admin").value(false))
                .andExpect(jsonPath("$.usuario.debeCambiarClave").value(true))
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andReturn().getResponse().getContentAsString();
        String acceso = JsonPath.read(r, "$.accessToken");

        mvc.perform(conToken(get("/api/v1/auth/yo"), acceso))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usuario.dni").value(dni));
        // la empresa sale del token (sin header X-Empresa-Id)
        mvc.perform(conToken(get("/api/v1/catalogos/variedades"), acceso)).andExpect(status().isOk());
    }

    @Test
    void sinToken_o_conTokenFalso_responde401() throws Exception {
        mvc.perform(get("/api/v1/lotes").header(SIN_TOKEN, "1"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.title").value("No autenticado"));
        mvc.perform(conToken(get("/api/v1/lotes"), "no.es.un-token")).andExpect(status().isUnauthorized());
    }

    @Test
    void claveIncorrecta_401_yTrasCincoFallosSeBloqueaElDni() throws Exception {
        for (int i = 0; i < 5; i++) {
            login(dni, "otra-clave-x")
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.detail").value("DNI o contraseña incorrectos"));
        }
        // bloqueado aunque ahora la clave sea la correcta
        login(dni, CLAVE).andExpect(status().isTooManyRequests());
        // un DNI que no existe responde igual que una clave incorrecta
        login(dniAlAzar(), CLAVE).andExpect(status().isUnauthorized());
    }

    @Test
    void usuarioDesactivado_noEntra() throws Exception {
        jdbc.sql("UPDATE usuario SET activo = false WHERE id = :id::uuid").param("id", usuarioId).update();
        login(dni, CLAVE).andExpect(status().isUnauthorized());
    }

    @Test
    void refresh_rotaElToken_yElAnteriorDejaDeServir() throws Exception {
        String refresh1 = JsonPath.read(login(dni, CLAVE).andReturn().getResponse().getContentAsString(), "$.refreshToken");

        String r = refrescar(refresh1).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String refresh2 = JsonPath.read(r, "$.refreshToken");
        assertThat(refresh2).isNotEqualTo(refresh1);

        refrescar(refresh1).andExpect(status().isUnauthorized());
        refrescar(refresh2).andExpect(status().isOk());
    }

    @Test
    void logout_cierraLaSesion() throws Exception {
        String refresh = JsonPath.read(login(dni, CLAVE).andReturn().getResponse().getContentAsString(), "$.refreshToken");
        mvc.perform(post("/api/v1/auth/logout").header(SIN_TOKEN, "1").contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refreshToken":"%s"}""".formatted(refresh)))
                .andExpect(status().isNoContent());
        refrescar(refresh).andExpect(status().isUnauthorized());
    }

    @Test
    void cambiarClave_quitaLaClaveTemporal_yCierraLasOtrasSesiones() throws Exception {
        String otroCelular = JsonPath.read(login(dni, CLAVE).andReturn().getResponse().getContentAsString(), "$.refreshToken");
        String acceso = JsonPath.read(login(dni, CLAVE).andReturn().getResponse().getContentAsString(), "$.accessToken");

        mvc.perform(conToken(put("/api/v1/auth/clave"), acceso).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"actual":"equivocada","nueva":"nueva-clave-22"}"""))
                .andExpect(status().isUnprocessableContent());
        mvc.perform(conToken(put("/api/v1/auth/clave"), acceso).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"actual":"%s","nueva":"corta"}""".formatted(CLAVE)))
                .andExpect(status().isBadRequest());
        mvc.perform(conToken(put("/api/v1/auth/clave"), acceso).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"actual":"%s","nueva":"nueva-clave-22"}""".formatted(CLAVE)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usuario.debeCambiarClave").value(false));

        refrescar(otroCelular).andExpect(status().isUnauthorized());
        login(dni, CLAVE).andExpect(status().isUnauthorized());
        login(dni, "nueva-clave-22").andExpect(status().isOk());
    }

    @Test
    void soloElAdministrador_gestionaUsuarios() throws Exception {
        String accesoEvaluador = JsonPath.read(login(dni, CLAVE).andReturn().getResponse().getContentAsString(), "$.accessToken");
        String adminDni = dniAlAzar();
        crearUsuario(adminDni, CLAVE, "ADMIN", false);
        String accesoAdmin = JsonPath.read(login(adminDni, CLAVE).andReturn().getResponse().getContentAsString(), "$.accessToken");

        // cualquiera lista usuarios (evaluadores), pero solo el admin crea o restablece claves
        mvc.perform(conToken(get("/api/v1/usuarios"), accesoEvaluador)).andExpect(status().isOk());
        mvc.perform(conToken(put("/api/v1/usuarios/" + usuarioId + "/clave"), accesoEvaluador)
                        .contentType(MediaType.APPLICATION_JSON).content("""
                                {"clave":"temporal-123"}"""))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.title").value("Sin permiso"));

        String nuevoDni = dniAlAzar();
        mvc.perform(conToken(post("/api/v1/usuarios"), accesoAdmin).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"nombres":"Nuevo Evaluador","dni":"%s","rol":"EVALUADOR","clave":"temporal-123"}"""
                                .formatted(nuevoDni)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tieneClave").value(true));
        login(nuevoDni, "temporal-123").andExpect(status().isOk())
                .andExpect(jsonPath("$.usuario.debeCambiarClave").value(true));

        mvc.perform(conToken(put("/api/v1/usuarios/" + usuarioId + "/clave"), accesoAdmin)
                        .contentType(MediaType.APPLICATION_JSON).content("""
                                {"clave":"temporal-123"}"""))
                .andExpect(status().isOk());
        login(dni, CLAVE).andExpect(status().isUnauthorized());
        login(dni, "temporal-123").andExpect(status().isOk());
    }

    @Test
    void loQueRegistraUnUsuario_quedaConSuId() throws Exception {
        String acceso = JsonPath.read(login(dni, CLAVE).andReturn().getResponse().getContentAsString(), "$.accessToken");
        String r = mvc.perform(conToken(post("/api/v1/catalogos/variedades"), acceso).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"cultivoId":"%s","codigo":"AUD","nombre":"AUDITADA"}""".formatted(cultivoAjo())))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String id = JsonPath.read(r, "$.id");
        UUID creadoPor = jdbc.sql("SELECT created_by FROM variedad WHERE id = :id::uuid").param("id", id)
                .query(UUID.class).single();
        assertThat(creadoPor).hasToString(usuarioId);
    }

    private String crearUsuario(String dni, String clave, String rol, boolean temporal) {
        return jdbc.sql("""
                        INSERT INTO usuario (empresa_id, nombres, dni, rol, clave_hash, debe_cambiar_clave)
                        VALUES (:empresa::uuid, :nombres, :dni, :rol, :hash, :temporal) RETURNING id""")
                .param("empresa", empresa)
                .param("nombres", "Usuario " + dni)
                .param("dni", dni)
                .param("rol", rol)
                .param("hash", encoder.encode(clave))
                .param("temporal", temporal)
                .query(UUID.class)
                .single()
                .toString();
    }

    private ResultActions login(String dni, String clave) throws Exception {
        return mvc.perform(post("/api/v1/auth/login").header(SIN_TOKEN, "1").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"dni":"%s","clave":"%s","dispositivo":"test"}""".formatted(dni, clave)));
    }

    private ResultActions refrescar(String refresh) throws Exception {
        return mvc.perform(post("/api/v1/auth/refresh").header(SIN_TOKEN, "1").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"refreshToken":"%s"}""".formatted(refresh)));
    }

    private static MockHttpServletRequestBuilder conToken(MockHttpServletRequestBuilder req, String token) {
        return req.header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
    }
}
