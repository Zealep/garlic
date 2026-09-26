package com.zealep.garlicbackend.evaluacion.dto;

import com.zealep.garlicbackend.evaluacion.EstadoEvaluacion;
import com.zealep.garlicbackend.evaluacion.NivelHumedad;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record EvaluacionResponse(
        UUID id,
        UUID loteId,
        String loteCodigo,
        Evaluador evaluador,
        LocalDate fechaEvaluacion,
        String observacion,
        EstadoEvaluacion estado,
        List<Muestra> muestras,
        Promedios promedios,
        List<Humedad> humedad,
        List<Item> empastes,
        List<Item> danos,
        List<Sanidad> sanidad,
        Instant createdAt,
        Instant updatedAt) {

    public record Evaluador(UUID id, String nombres) {
    }

    /** Elemento de catalogo resumido. */
    public record Item(UUID id, String codigo, String nombre) {
    }

    public record ValorPorcentaje(UUID id, String codigo, String nombre, BigDecimal porcentaje) {
    }

    public record Muestra(UUID id, short numero, String observacion,
            List<ValorPorcentaje> calidad, List<ValorPorcentaje> calibres) {
    }

    /** Columna PROM del protocolo: promedio de las muestras que registran cada clase / calibre. */
    public record Promedios(List<ValorPorcentaje> calidad, List<ValorPorcentaje> calibres) {
    }

    public record Humedad(UUID id, String codigo, String nombre, NivelHumedad nivel) {
    }

    public record Sanidad(UUID id, String codigo, String nombre, boolean presente, BigDecimal porcentaje) {
    }
}
