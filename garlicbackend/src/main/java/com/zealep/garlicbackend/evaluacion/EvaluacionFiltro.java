package com.zealep.garlicbackend.evaluacion;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Filtros opcionales de la bandeja de evaluaciones.
 */
public record EvaluacionFiltro(EstadoEvaluacion estado, UUID loteId, LocalDate desde, LocalDate hasta) {
}
