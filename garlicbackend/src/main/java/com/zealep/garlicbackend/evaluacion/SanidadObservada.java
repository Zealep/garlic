package com.zealep.garlicbackend.evaluacion;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * 2.2.4 / 2.2.5 Fila de evaluacion_sanidad: enfermedad SI/NO y % si esta presente.
 */
@Embeddable
public record SanidadObservada(
        @Column(name = "enfermedad_id", nullable = false) UUID enfermedadId,
        @Column(name = "presente", nullable = false) boolean presente,
        @Column(name = "porcentaje", precision = 5, scale = 2) BigDecimal porcentaje) {
}
