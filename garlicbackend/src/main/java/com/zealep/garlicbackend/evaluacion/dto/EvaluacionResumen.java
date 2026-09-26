package com.zealep.garlicbackend.evaluacion.dto;

import com.zealep.garlicbackend.evaluacion.EstadoEvaluacion;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Fila de listado de evaluaciones (historial del lote o bandeja general).
 */
public record EvaluacionResumen(
        UUID id,
        UUID loteId,
        String loteCodigo,
        String zona,
        LocalDate fechaEvaluacion,
        EstadoEvaluacion estado,
        String evaluador,
        int nroMuestras,
        Instant createdAt) {
}
