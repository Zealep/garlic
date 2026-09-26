package com.zealep.garlicbackend.tercero.persona;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Datos de identidad. Se usa tambien para registrar agricultores y proveedores.
 */
@DocumentoValido
public record PersonaRequest(
        @NotNull TipoDocumento tipoDocumento,
        @NotBlank @Size(max = 20) String numeroDocumento,
        @NotBlank @Size(max = 200) String nombres,
        @Size(max = 20) String telefono) implements ConDocumento {
}
