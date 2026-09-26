package com.zealep.garlicbackend.tercero.persona;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class DocumentoValidoValidator implements ConstraintValidator<DocumentoValido, ConDocumento> {

    @Override
    public boolean isValid(ConDocumento value, ConstraintValidatorContext context) {
        // Los nulos los reportan @NotNull / @NotBlank de cada campo
        if (value == null || value.tipoDocumento() == null || value.numeroDocumento() == null) {
            return true;
        }
        TipoDocumento tipo = value.tipoDocumento();
        if (tipo.esValido(Persona.normalizarDocumento(value.numeroDocumento()))) {
            return true;
        }
        context.disableDefaultConstraintViolation();
        context.buildConstraintViolationWithTemplate("un " + tipo + " debe tener " + tipo.descripcionFormato())
                .addPropertyNode("numeroDocumento")
                .addConstraintViolation();
        return false;
    }
}
