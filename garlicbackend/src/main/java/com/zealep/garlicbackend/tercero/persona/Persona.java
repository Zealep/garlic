package com.zealep.garlicbackend.tercero.persona;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.util.Locale;

/**
 * Identidad compartida por agricultores, proveedores y titulares de la liquidacion de compra.
 */
@Entity
@Table(name = "persona")
public class Persona extends TenantEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_documento", nullable = false, length = 10)
    private TipoDocumento tipoDocumento;

    @Column(name = "numero_documento", nullable = false, length = 20)
    private String numeroDocumento;

    @Column(name = "nombres", nullable = false, length = 200)
    private String nombres;

    @Column(name = "telefono", length = 20)
    private String telefono;

    /** Sin espacios y en mayusculas, para comparar documentos de forma consistente. */
    public static String normalizarDocumento(String numero) {
        return numero == null ? null : numero.replaceAll("\\s+", "").toUpperCase(Locale.ROOT);
    }

    public TipoDocumento getTipoDocumento() {
        return tipoDocumento;
    }

    public void setTipoDocumento(TipoDocumento tipoDocumento) {
        this.tipoDocumento = tipoDocumento;
    }

    public String getNumeroDocumento() {
        return numeroDocumento;
    }

    public void setNumeroDocumento(String numeroDocumento) {
        this.numeroDocumento = normalizarDocumento(numeroDocumento);
    }

    public String getNombres() {
        return nombres;
    }

    public void setNombres(String nombres) {
        this.nombres = nombres == null ? null : nombres.trim().replaceAll("\\s+", " ");
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono == null || telefono.isBlank() ? null : telefono.trim();
    }
}
