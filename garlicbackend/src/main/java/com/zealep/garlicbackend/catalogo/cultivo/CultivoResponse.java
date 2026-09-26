package com.zealep.garlicbackend.catalogo.cultivo;

import java.util.UUID;

public record CultivoResponse(UUID id, String codigo, String nombre) {

    static CultivoResponse from(Cultivo cultivo) {
        return new CultivoResponse(cultivo.getId(), cultivo.getCodigo(), cultivo.getNombre());
    }
}
