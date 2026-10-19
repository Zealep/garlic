package com.zealep.garlicbackend.evaluacion;

/**
 * Dictamen de una evaluacion cerrada. No bloquea la compra: un lote rechazado puede comprarse
 * igual (por necesidad de producto).
 */
public enum ResultadoEvaluacion {
    /** El lote cumple y se acepta. */
    ACEPTADA,
    /** El lote no cumple. */
    RECHAZADA,
    /** No se cerro con el agricultor: no hubo acuerdo de precio. */
    SIN_ACUERDO
}
