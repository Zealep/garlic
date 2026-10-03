package com.zealep.garlicbackend.catalogo.tipogasto;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "tipo_gasto")
public class TipoGasto extends CatalogoCultivoEntity {

    @Column(name = "por_carga", nullable = false)
    private boolean porCarga;

    @Column(name = "requiere_descripcion", nullable = false)
    private boolean requiereDescripcion;

    public boolean isPorCarga() {
        return porCarga;
    }

    public void setPorCarga(boolean porCarga) {
        this.porCarga = porCarga;
    }

    public boolean isRequiereDescripcion() {
        return requiereDescripcion;
    }

    public void setRequiereDescripcion(boolean requiereDescripcion) {
        this.requiereDescripcion = requiereDescripcion;
    }
}
