package com.zealep.garlicbackend.tercero.persona;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Valida que el numero de documento cumpla el formato de su tipo (DNI = 8 digitos, RUC = 11, ...).
 * El error se reporta sobre el campo {@code numeroDocumento}.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = DocumentoValidoValidator.class)
public @interface DocumentoValido {

    String message() default "numero de documento invalido";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
