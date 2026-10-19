package com.zealep.garlicbackend.evaluacion.dto;

import com.zealep.garlicbackend.evaluacion.ResultadoEvaluacion;
import jakarta.validation.constraints.Size;

/**
 * Dictamen de una evaluacion cerrada.
 *
 * @param resultado null = vuelve a pendiente
 * @param motivo    por que se rechazo / no hubo acuerdo (opcional)
 */
public record ResultadoRequest(ResultadoEvaluacion resultado, @Size(max = 500) String motivo) {
}
