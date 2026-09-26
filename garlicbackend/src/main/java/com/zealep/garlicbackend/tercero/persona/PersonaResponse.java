package com.zealep.garlicbackend.tercero.persona;

import java.time.Instant;
import java.util.UUID;

public record PersonaResponse(
        UUID id,
        TipoDocumento tipoDocumento,
        String numeroDocumento,
        String nombres,
        String telefono,
        Instant createdAt,
        Instant updatedAt) {
}
