package com.zealep.garlicbackend.evaluacion;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.util.UUID;

/**
 * 2.2.1 Fila de muestra_humedad: indicador observado SI/NO.
 */
@Embeddable
public record HumedadObservada(
        @Column(name = "tipo_humedad_id", nullable = false) UUID tipoHumedadId,
        @Column(name = "presente", nullable = false) boolean presente) {
}
