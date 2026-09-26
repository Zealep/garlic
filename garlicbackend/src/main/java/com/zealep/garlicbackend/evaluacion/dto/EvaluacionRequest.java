package com.zealep.garlicbackend.evaluacion.dto;

import com.zealep.garlicbackend.evaluacion.NivelHumedad;
import com.zealep.garlicbackend.shared.validation.Porcentaje;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Contenido completo de la evaluacion (se reemplaza en cada guardado mientras esta en BORRADOR).
 * Las listas nulas se toman como vacias.
 *
 * @param id opcional: UUID generado por el cliente (app offline). Al crear, si ya existe se devuelve la existente.
 */
public record EvaluacionRequest(
        UUID id,
        @NotNull UUID evaluadorId,
        @NotNull LocalDate fechaEvaluacion,
        @Size(max = 4000) String observacion,
        @Size(max = 20) List<@Valid @NotNull Muestra> muestras,
        List<@Valid @NotNull Humedad> humedad,
        List<@NotNull UUID> empastes,
        List<@NotNull UUID> danos,
        List<@Valid @NotNull Sanidad> sanidad) {

    public List<Muestra> muestrasOVacio() {
        return muestras == null ? List.of() : muestras;
    }

    public List<Humedad> humedadOVacio() {
        return humedad == null ? List.of() : humedad;
    }

    public List<UUID> empastesOVacio() {
        return empastes == null ? List.of() : empastes;
    }

    public List<UUID> danosOVacio() {
        return danos == null ? List.of() : danos;
    }

    public List<Sanidad> sanidadOVacio() {
        return sanidad == null ? List.of() : sanidad;
    }

    /** Muestra con sus % de calidad (2.1) y calibre (2.2). */
    public record Muestra(
            @NotNull @Positive Short numero,
            @Size(max = 2000) String observacion,
            List<@Valid @NotNull Calidad> calidad,
            List<@Valid @NotNull Calibre> calibres) {

        public List<Calidad> calidadOVacio() {
            return calidad == null ? List.of() : calidad;
        }

        public List<Calibre> calibresOVacio() {
            return calibres == null ? List.of() : calibres;
        }
    }

    public record Calidad(@NotNull UUID claseCalidadId, @NotNull @Porcentaje BigDecimal porcentaje) {
    }

    public record Calibre(@NotNull UUID calibreId, @NotNull @Porcentaje BigDecimal porcentaje) {
    }

    /** 2.2.1 Indicador de humedad observado y su nivel. */
    public record Humedad(@NotNull UUID tipoHumedadId, @NotNull NivelHumedad nivel) {
    }

    /** 2.2.4 / 2.2.5 SI/NO y, si es SI, el porcentaje. */
    public record Sanidad(@NotNull UUID enfermedadId, @NotNull Boolean presente, @Porcentaje BigDecimal porcentaje) {
    }
}
