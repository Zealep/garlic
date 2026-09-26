package com.zealep.garlicbackend.catalogo.calibre;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.math.BigDecimal;

@Entity
@Table(name = "calibre")
public class Calibre extends CatalogoCultivoEntity {

    @Column(name = "diametro_min_mm", precision = 5, scale = 1)
    private BigDecimal diametroMinMm;

    @Column(name = "diametro_max_mm", precision = 5, scale = 1)
    private BigDecimal diametroMaxMm;

    public BigDecimal getDiametroMinMm() {
        return diametroMinMm;
    }

    public void setDiametroMinMm(BigDecimal diametroMinMm) {
        this.diametroMinMm = diametroMinMm;
    }

    public BigDecimal getDiametroMaxMm() {
        return diametroMaxMm;
    }

    public void setDiametroMaxMm(BigDecimal diametroMaxMm) {
        this.diametroMaxMm = diametroMaxMm;
    }
}
