package com.zealep.garlicbackend.evaluacion;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * 2.2 Fila de muestra_calibre: % de un calibre en la muestra.
 */
@Embeddable
public record PorcentajeCalibre(
        @Column(name = "calibre_id", nullable = false) UUID calibreId,
        @Column(name = "porcentaje", nullable = false, precision = 5, scale = 2) BigDecimal porcentaje) {
}
