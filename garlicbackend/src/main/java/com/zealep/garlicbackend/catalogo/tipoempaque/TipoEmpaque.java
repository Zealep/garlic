package com.zealep.garlicbackend.catalogo.tipoempaque;

import com.zealep.garlicbackend.catalogo.base.CatalogoCultivoEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.math.BigDecimal;

@Entity
@Table(name = "tipo_empaque")
public class TipoEmpaque extends CatalogoCultivoEntity {

    @Column(name = "peso_referencial_kg", precision = 8, scale = 2)
    private BigDecimal pesoReferencialKg;

    public BigDecimal getPesoReferencialKg() {
        return pesoReferencialKg;
    }

    public void setPesoReferencialKg(BigDecimal pesoReferencialKg) {
        this.pesoReferencialKg = pesoReferencialKg;
    }
}
