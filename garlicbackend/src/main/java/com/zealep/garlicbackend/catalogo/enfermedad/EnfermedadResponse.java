package com.zealep.garlicbackend.catalogo.enfermedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.util.UUID;

public record EnfermedadResponse(
        UUID id,
        UUID cultivoId,
        String codigo,
        String nombre,
        Short orden,
        boolean activo,
        String nombreCientifico,
        Boolean seTransmitePorSemilla,
        Boolean evaluarEnCampo,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
