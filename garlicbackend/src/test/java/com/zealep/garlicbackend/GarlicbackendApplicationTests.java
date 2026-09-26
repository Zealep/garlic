package com.zealep.garlicbackend;

import com.zealep.garlicbackend.support.TestcontainersConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

/**
 * Verifica que el contexto levanta contra Postgres real: Flyway migra y
 * Hibernate valida que las entidades coinciden con el esquema (ddl-auto=validate).
 */
@SpringBootTest
@Import(TestcontainersConfiguration.class)
class GarlicbackendApplicationTests {

    @Test
    void contextLoads() {
    }
}
