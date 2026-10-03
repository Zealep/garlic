package com.zealep.garlicbackend.compra.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Fijacion de precio del lote (se reemplaza completa en cada guardado).
 *
 * @param evaluacionId  evaluacion CERRADA del lote de la que se toman los % de calidad
 * @param precios       precio base (S/ por kg) por clase de calidad
 * @param gastoLlenado  S/ por kg que se resta al promedio de las muestras
 * @param precioPactado precio final acordado con el agricultor/proveedor (null = aun no se pacta)
 */
public record FijacionRequest(
        @NotNull UUID evaluacionId,
        @Size(max = 30) List<@Valid @NotNull PrecioClase> precios,
        @DecimalMin("0.0") @Digits(integer = 6, fraction = 4) BigDecimal gastoLlenado,
        @DecimalMin(value = "0.0", inclusive = false) @Digits(integer = 6, fraction = 4) BigDecimal precioPactado,
        LocalDate fechaPacto,
        @Size(max = 4000) String observacion) {

    public List<PrecioClase> preciosOVacio() {
        return precios == null ? List.of() : precios;
    }

    public record PrecioClase(
            @NotNull UUID claseCalidadId,
            @NotNull @DecimalMin("0.0") @Digits(integer = 6, fraction = 4) BigDecimal precioBase) {
    }
}
