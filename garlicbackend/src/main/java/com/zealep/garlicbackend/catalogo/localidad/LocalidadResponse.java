package com.zealep.garlicbackend.catalogo.localidad;

import com.zealep.garlicbackend.catalogo.base.CatalogoResponse;
import java.time.Instant;
import java.util.UUID;

public record LocalidadResponse(
        UUID id,
        String nombre,
        TipoLocalidad tipo,
        String ubigeo,
        boolean activo,
        Instant createdAt,
        Instant updatedAt) implements CatalogoResponse {
}
