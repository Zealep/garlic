package com.zealep.garlicbackend.evaluacion.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * % de calidad (2.1) de cada muestra de una evaluacion; lo usa la fijacion de precio.
 *
 * @param cerrada solo una evaluacion cerrada sirve para fijar el precio
 */
public record CalidadPorMuestra(UUID evaluacionId, boolean cerrada, LocalDate fechaEvaluacion, List<MuestraCalidad> muestras) {

    /** @param calidad clase de calidad -> porcentaje (0-100) */
    public record MuestraCalidad(short numero, Map<UUID, BigDecimal> calidad) {
    }
}
