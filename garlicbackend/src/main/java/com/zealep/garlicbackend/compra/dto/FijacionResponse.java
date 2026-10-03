package com.zealep.garlicbackend.compra.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Fijacion de precio con los valores calculados por el servidor.
 *
 * @param ajuste precio pactado - precio tecnico
 */
public record FijacionResponse(
        UUID id,
        UUID loteId,
        UUID evaluacionId,
        LocalDate fechaEvaluacion,
        List<PrecioClase> precios,
        List<PrecioMuestra> preciosMuestra,
        BigDecimal gastoLlenado,
        BigDecimal precioPromedio,
        BigDecimal precioTecnico,
        BigDecimal precioPactado,
        BigDecimal ajuste,
        LocalDate fechaPacto,
        String observacion,
        Instant updatedAt) {

    public record PrecioClase(UUID claseCalidadId, String codigo, String nombre, BigDecimal precioBase) {
    }

    public record PrecioMuestra(short numero, BigDecimal precio) {
    }
}
