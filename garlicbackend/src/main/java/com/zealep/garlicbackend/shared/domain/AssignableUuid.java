package com.zealep.garlicbackend.shared.domain;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import org.hibernate.annotations.IdGeneratorType;

/**
 * Id UUID que se genera si viene vacio, pero respeta el id asignado por el cliente.
 * Permite que la app movil cree registros sin conexion con su propio UUID y los sincronice
 * despues sin duplicarlos (creacion idempotente).
 */
@IdGeneratorType(AssignableUuidGenerator.class)
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.FIELD, ElementType.METHOD})
public @interface AssignableUuid {
}
