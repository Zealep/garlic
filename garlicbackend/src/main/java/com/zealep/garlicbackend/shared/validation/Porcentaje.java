package com.zealep.garlicbackend.shared.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import jakarta.validation.ReportAsSingleViolation;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Porcentaje de 0 a 100 con hasta 2 decimales (columnas numeric(5,2)).
 */
@DecimalMin("0")
@DecimalMax("100")
@Digits(integer = 3, fraction = 2)
@ReportAsSingleViolation
@Constraint(validatedBy = {})
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT, ElementType.TYPE_USE})
@Retention(RetentionPolicy.RUNTIME)
public @interface Porcentaje {

    String message() default "debe estar entre 0 y 100 con hasta 2 decimales";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
