package com.zealep.garlicbackend.evaluacion;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

/**
 * Fila de muestra_dano: dano no visible marcado y, si el tipo lo pide (paralisis), los frutos contados.
 */
@Embeddable
public record DanoObservado(
        @Column(name = "tipo_dano_id", nullable = false) UUID tipoDanoId,
        @Column(name = "frutos_total") Integer frutosTotal,
        @Column(name = "frutos_afectados") Integer frutosAfectados) {

    /** % de dano = afectados / total x 100 (2 decimales); null sin cantidades. */
    public BigDecimal porcentaje() {
        if (frutosTotal == null || frutosAfectados == null || frutosTotal == 0) {
            return null;
        }
        return BigDecimal.valueOf(frutosAfectados).multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(frutosTotal), 2, RoundingMode.HALF_UP);
    }
}
