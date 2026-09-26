package com.zealep.garlicbackend.tercero.persona;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import java.util.Set;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class DocumentoValidoValidatorTest {

    private static ValidatorFactory factory;
    private static Validator validator;

    @BeforeAll
    static void init() {
        factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @AfterAll
    static void close() {
        factory.close();
    }

    @ParameterizedTest
    @CsvSource({
            "DNI, 72790829",
            "DNI, ' 7279 0829 '",
            "RUC, 20123456789",
            "CE, 00123456a",
            "PASAPORTE, AB12345"})
    void documentosValidos(TipoDocumento tipo, String numero) {
        assertThat(validator.validate(new PersonaRequest(tipo, numero, "Kevin", null))).isEmpty();
    }

    @ParameterizedTest
    @CsvSource({
            "DNI, 1234567",
            "DNI, 1234567A",
            "RUC, 2012345678",
            "CE, 1234",
            "PASAPORTE, AB-123"})
    void documentosInvalidos_reportanErrorEnNumeroDocumento(TipoDocumento tipo, String numero) {
        Set<ConstraintViolation<PersonaRequest>> errores = validator.validate(new PersonaRequest(tipo, numero, "Kevin", null));

        assertThat(errores).hasSize(1);
        ConstraintViolation<PersonaRequest> error = errores.iterator().next();
        assertThat(error.getPropertyPath()).hasToString("numeroDocumento");
        assertThat(error.getMessage()).contains(tipo.name());
    }

    @Test
    void sinTipo_soloReportaNotNull() {
        Set<ConstraintViolation<PersonaRequest>> errores = validator.validate(new PersonaRequest(null, "123", "Kevin", null));

        assertThat(errores).extracting(v -> v.getPropertyPath().toString()).containsExactly("tipoDocumento");
    }
}
