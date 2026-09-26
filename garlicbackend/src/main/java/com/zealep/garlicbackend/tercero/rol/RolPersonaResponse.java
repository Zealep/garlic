package com.zealep.garlicbackend.tercero.rol;

import com.zealep.garlicbackend.tercero.persona.PersonaResponse;
import java.time.Instant;
import java.util.UUID;

public record RolPersonaResponse(
        UUID id,
        boolean activo,
        PersonaResponse persona,
        Instant createdAt,
        Instant updatedAt) {
}
