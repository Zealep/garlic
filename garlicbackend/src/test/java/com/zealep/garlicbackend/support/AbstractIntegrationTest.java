package com.zealep.garlicbackend.support;

import com.zealep.garlicbackend.shared.tenant.TenantContext;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Base de los tests de integracion: contexto completo + Postgres (Testcontainers) + MockMvc.
 * Todas las subclases comparten el mismo contexto (y contenedor) gracias al cache de Spring.
 */
@SpringBootTest(properties = "garlic.storage.directorio=target/test-evidencias")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
public abstract class AbstractIntegrationTest {

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected JdbcClient jdbc;

    /** Crea una empresa nueva (tenant aislado) y devuelve su id. */
    protected String nuevaEmpresa() {
        String ruc = String.valueOf(ThreadLocalRandom.current().nextLong(10_000_000_000L, 99_999_999_999L));
        return jdbc.sql("INSERT INTO empresa (ruc, razon_social) VALUES (:ruc, :rs) RETURNING id")
                .param("ruc", ruc)
                .param("rs", "Empresa test " + ruc)
                .query(UUID.class)
                .single()
                .toString();
    }

    protected String cultivoAjo() {
        return jdbc.sql("SELECT id FROM cultivo WHERE codigo = 'AJO'").query(UUID.class).single().toString();
    }

    /** Request JSON con el header de empresa. */
    protected static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder req, String empresa, String body) {
        return req.header(TenantContext.HEADER, empresa).contentType(MediaType.APPLICATION_JSON).content(body);
    }
}
