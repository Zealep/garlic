package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * 3.2 Compra de materia prima: un camion (carga) del lote.
 */
@Entity
@Table(name = "carga")
public class Carga extends TenantEntity {

    @Column(name = "lote_id", nullable = false, updatable = false)
    private UUID loteId;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "placa", length = 15)
    private String placa;

    @Column(name = "kg", nullable = false, precision = 12, scale = 2)
    private BigDecimal kg;

    @Column(name = "cantidad_empaques", nullable = false)
    private int cantidadEmpaques;

    @Column(name = "tipo_empaque_id")
    private UUID tipoEmpaqueId;

    @Column(name = "precio_kg", nullable = false, precision = 10, scale = 4)
    private BigDecimal precioKg;

    @Column(name = "destare_pct", nullable = false, precision = 5, scale = 2)
    private BigDecimal destarePct;

    @Column(name = "observacion")
    private String observacion;

    protected Carga() {
    }

    public Carga(UUID empresaId, UUID loteId) {
        setEmpresaId(empresaId);
        this.loteId = loteId;
    }

    public CalculoCompra.LineaCarga calcular() {
        return CalculoCompra.carga(kg, precioKg, destarePct);
    }

    public UUID getLoteId() {
        return loteId;
    }

    public LocalDate getFecha() {
        return fecha;
    }

    public void setFecha(LocalDate fecha) {
        this.fecha = fecha;
    }

    public String getPlaca() {
        return placa;
    }

    public void setPlaca(String placa) {
        this.placa = placa;
    }

    public BigDecimal getKg() {
        return kg;
    }

    public void setKg(BigDecimal kg) {
        this.kg = kg;
    }

    public int getCantidadEmpaques() {
        return cantidadEmpaques;
    }

    public void setCantidadEmpaques(int cantidadEmpaques) {
        this.cantidadEmpaques = cantidadEmpaques;
    }

    public UUID getTipoEmpaqueId() {
        return tipoEmpaqueId;
    }

    public void setTipoEmpaqueId(UUID tipoEmpaqueId) {
        this.tipoEmpaqueId = tipoEmpaqueId;
    }

    public BigDecimal getPrecioKg() {
        return precioKg;
    }

    public void setPrecioKg(BigDecimal precioKg) {
        this.precioKg = precioKg;
    }

    public BigDecimal getDestarePct() {
        return destarePct;
    }

    public void setDestarePct(BigDecimal destarePct) {
        this.destarePct = destarePct;
    }

    public String getObservacion() {
        return observacion;
    }

    public void setObservacion(String observacion) {
        this.observacion = observacion;
    }
}
