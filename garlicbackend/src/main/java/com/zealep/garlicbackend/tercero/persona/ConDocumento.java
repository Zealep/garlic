package com.zealep.garlicbackend.tercero.persona;

/**
 * Todo DTO que trae un documento de identidad a validar con {@link DocumentoValido}.
 */
public interface ConDocumento {

    TipoDocumento tipoDocumento();

    String numeroDocumento();
}
