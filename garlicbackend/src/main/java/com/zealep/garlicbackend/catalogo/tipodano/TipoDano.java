package com.zealep.garlicbackend.catalogo.tipodano;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "tipo_dano")
public class TipoDano extends CatalogoCultivoEntity {

    @Column(name = "es_excluyente", nullable = false)
    private boolean esExcluyente;

    /** Al marcarlo se piden frutos total y afectados (% de dano), p. ej. paralisis. */
    @Column(name = "pide_cantidades", nullable = false)
    private boolean pideCantidades;

    public boolean isEsExcluyente() {
        return esExcluyente;
    }

    public void setEsExcluyente(boolean esExcluyente) {
        this.esExcluyente = esExcluyente;
    }

    public boolean isPideCantidades() {
        return pideCantidades;
    }

    public void setPideCantidades(boolean pideCantidades) {
        this.pideCantidades = pideCantidades;
    }
}
