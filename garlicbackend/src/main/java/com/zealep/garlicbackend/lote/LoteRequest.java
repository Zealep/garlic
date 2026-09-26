package com.zealep.garlicbackend.lote;

import com.zealep.garlicbackend.tercero.persona.PersonaRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Identificacion del lote.
 *
 * @param id                 opcional: UUID generado por el cliente (app offline). Si ya existe se devuelve el existente.
 * @param titularLiquidacion DNI LC: datos de quien figura en la liquidacion de compra.
 *                           Si el documento ya existe se reutiliza la persona.
 */
public record LoteRequest(
        UUID id,
        @NotNull UUID campaniaId,
        @NotBlank @Size(max = 30) String codigo,
        @NotNull UUID variedadId,
        @NotNull UUID agricultorId,
        UUID proveedorId,
        @Valid PersonaRequest titularLiquidacion,
        @NotNull UUID localidadId,
        @NotBlank @Size(max = 50) String zona,
        @DecimalMin("-90") @DecimalMax("90") @Digits(integer = 3, fraction = 6) BigDecimal latitud,
        @DecimalMin("-180") @DecimalMax("180") @Digits(integer = 3, fraction = 6) BigDecimal longitud,
        @Size(max = 2000) String mapsUrl,
        @NotNull UUID tipoCompraId,
        LocalDate fechaArrancado,
        LocalDate fechaCorte,
        LocalDate fechaCarga) {
}
