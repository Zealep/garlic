package com.zealep.garlicbackend.catalogo.base;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import java.util.Locale;
import java.util.UUID;

/**
 * Estructura comun de catalogos por cultivo: cultivo, codigo, nombre y orden.
 */
@MappedSuperclass
public abstract class CatalogoCultivoEntity extends CatalogoEntity {

    @Column(name = "cultivo_id", nullable = false)
    private UUID cultivoId;

    @Column(name = "codigo", nullable = false, length = 30)
    private String codigo;

    @Column(name = "nombre", nullable = false, length = 120)
    private String nombre;

    @Column(name = "orden", nullable = false)
    private Short orden = 0;

    public UUID getCultivoId() {
        return cultivoId;
    }

    public void setCultivoId(UUID cultivoId) {
        this.cultivoId = cultivoId;
    }

    public String getCodigo() {
        return codigo;
    }

    /** El codigo se guarda normalizado: sin espacios extremos y en mayusculas. */
    public void setCodigo(String codigo) {
        this.codigo = codigo == null ? null : codigo.trim().toUpperCase(Locale.ROOT);
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre == null ? null : nombre.trim();
    }

    public Short getOrden() {
        return orden;
    }

    /** PUT es reemplazo completo: sin orden se asume 0. */
    public void setOrden(Short orden) {
        this.orden = orden == null ? 0 : orden;
    }
}
