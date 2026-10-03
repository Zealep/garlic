package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * 3.1 Abono / adelanto al agricultor o proveedor, solo por la materia prima.
 */
@Entity
@Table(name = "pago")
public class Pago extends TenantEntity {

    @Column(name = "lote_id", nullable = false, updatable = false)
    private UUID loteId;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "condicion_pago_id", nullable = false)
    private UUID condicionPagoId;

    @Column(name = "monto", nullable = false, precision = 12, scale = 2)
    private BigDecimal monto;

    @Column(name = "beneficiario_id")
    private UUID beneficiarioId;

    @Column(name = "referencia", length = 60)
    private String referencia;

    @Column(name = "observacion")
    private String observacion;

    protected Pago() {
    }

    public Pago(UUID empresaId, UUID loteId) {
        setEmpresaId(empresaId);
        this.loteId = loteId;
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

    public UUID getCondicionPagoId() {
        return condicionPagoId;
    }

    public void setCondicionPagoId(UUID condicionPagoId) {
        this.condicionPagoId = condicionPagoId;
    }

    public BigDecimal getMonto() {
        return monto;
    }

    public void setMonto(BigDecimal monto) {
        this.monto = monto;
    }

    public UUID getBeneficiarioId() {
        return beneficiarioId;
    }

    public void setBeneficiarioId(UUID beneficiarioId) {
        this.beneficiarioId = beneficiarioId;
    }

    public String getReferencia() {
        return referencia;
    }

    public void setReferencia(String referencia) {
        this.referencia = referencia;
    }

    public String getObservacion() {
        return observacion;
    }

    public void setObservacion(String observacion) {
        this.observacion = observacion;
    }
}
