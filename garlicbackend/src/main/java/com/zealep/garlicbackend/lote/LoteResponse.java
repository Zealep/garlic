package com.zealep.garlicbackend.lote;

import com.zealep.garlicbackend.tercero.persona.TipoDocumento;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record LoteResponse(
        UUID id,
        String codigo,
        EstadoLote estado,
        CatalogoRef campania,
        UUID cultivoId,
        CatalogoRef variedad,
        PersonaRef agricultor,
        PersonaRef proveedor,
        PersonaRef titularLiquidacion,
        CatalogoRef localidad,
        String zona,
        BigDecimal latitud,
        BigDecimal longitud,
        String mapsUrl,
        CatalogoRef tipoCompra,
        LocalDate fechaArrancado,
        LocalDate fechaCorte,
        LocalDate fechaCarga,
        Instant createdAt,
        Instant updatedAt) {

    /** Referencia resumida a un catalogo. */
    public record CatalogoRef(UUID id, String codigo, String nombre) {
    }

    /**
     * Referencia resumida a una persona o rol.
     *
     * @param id id del rol (agricultor / proveedor) o de la persona (titular)
     */
    public record PersonaRef(UUID id, TipoDocumento tipoDocumento, String numeroDocumento, String nombres) {
    }
}
