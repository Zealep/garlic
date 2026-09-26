package com.zealep.garlicbackend.evaluacion;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * 2.1 Fila de muestra_calidad: % de una clase de calidad en la muestra.
 */
@Embeddable
public record PorcentajeCalidad(
        @Column(name = "clase_calidad_id", nullable = false) UUID claseCalidadId,
        @Column(name = "porcentaje", nullable = false, precision = 5, scale = 2) BigDecimal porcentaje) {
}
