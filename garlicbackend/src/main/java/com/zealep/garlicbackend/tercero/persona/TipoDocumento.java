package com.zealep.garlicbackend.tercero.persona;

import java.util.regex.Pattern;

/**
 * Tipos de documento de identidad y su formato valido.
 */
public enum TipoDocumento {
    DNI("\\d{8}", "8 digitos"),
    RUC("\\d{11}", "11 digitos"),
    CE("[A-Z0-9]{9,12}", "9 a 12 caracteres alfanumericos"),
    PASAPORTE("[A-Z0-9]{6,12}", "6 a 12 caracteres alfanumericos");

    private final Pattern formato;
    private final String descripcionFormato;

    TipoDocumento(String regex, String descripcionFormato) {
        this.formato = Pattern.compile(regex);
        this.descripcionFormato = descripcionFormato;
    }

    /** Valida un numero ya normalizado (ver {@link Persona#normalizarDocumento(String)}). */
    public boolean esValido(String numeroNormalizado) {
        return numeroNormalizado != null && formato.matcher(numeroNormalizado).matches();
    }

    public String descripcionFormato() {
        return descripcionFormato;
    }
}
