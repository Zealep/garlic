package com.zealep.garlicbackend.evaluacion.evidencia;

import java.time.Instant;
import java.util.UUID;

/**
 * @param url ruta de descarga del archivo en esta API
 */
public record EvidenciaResponse(
        UUID id,
        UUID evaluacionId,
        UUID muestraId,
        Short muestraNumero,
        FactorEvidencia factor,
        String descripcion,
        Instant fechaCaptura,
        String url,
        Instant createdAt) {

    static EvidenciaResponse from(Evidencia e) {
        return new EvidenciaResponse(
                e.getId(),
                e.getEvaluacion().getId(),
                e.getMuestra() == null ? null : e.getMuestra().getId(),
                e.getMuestra() == null ? null : e.getMuestra().getNumero(),
                e.getFactor(),
                e.getDescripcion(),
                e.getFechaCaptura(),
                "/api/v1/evidencias/" + e.getId() + "/archivo",
                e.getCreatedAt());
    }
}
