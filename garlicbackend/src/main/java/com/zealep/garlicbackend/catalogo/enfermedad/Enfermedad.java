package com.zealep.garlicbackend.catalogo.enfermedad;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "enfermedad")
public class Enfermedad extends CatalogoCultivoEntity {

    @Column(name = "nombre_cientifico", length = 150)
    private String nombreCientifico;

    @Column(name = "se_transmite_por_semilla", nullable = false)
    private boolean seTransmitePorSemilla;

    @Column(name = "evaluar_en_campo", nullable = false)
    private boolean evaluarEnCampo;

    public String getNombreCientifico() {
        return nombreCientifico;
    }

    public void setNombreCientifico(String nombreCientifico) {
        this.nombreCientifico = nombreCientifico;
    }

    public boolean isSeTransmitePorSemilla() {
        return seTransmitePorSemilla;
    }

    public void setSeTransmitePorSemilla(boolean seTransmitePorSemilla) {
        this.seTransmitePorSemilla = seTransmitePorSemilla;
    }

    public boolean isEvaluarEnCampo() {
        return evaluarEnCampo;
    }

    public void setEvaluarEnCampo(boolean evaluarEnCampo) {
        this.evaluarEnCampo = evaluarEnCampo;
    }
}
