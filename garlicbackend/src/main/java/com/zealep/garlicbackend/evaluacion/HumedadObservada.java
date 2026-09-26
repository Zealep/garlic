package com.zealep.garlicbackend.evaluacion;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * 2.2.1 Fila de evaluacion_humedad: indicador observado y su nivel.
 */
@Embeddable
public record HumedadObservada(
        @Column(name = "tipo_humedad_id", nullable = false) UUID tipoHumedadId,
        @Enumerated(EnumType.STRING)
        @JdbcTypeCode(SqlTypes.NAMED_ENUM)
        @Column(name = "nivel", nullable = false, columnDefinition = "nivel_enum") NivelHumedad nivel) {
}
