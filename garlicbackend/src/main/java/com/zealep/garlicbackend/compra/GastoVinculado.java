package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Gasto vinculado a la materia prima (llevar el producto al packing). Sin carga = gasto general del lote.
 */
@Entity
@Table(name = "gasto_vinculado")
public class GastoVinculado extends TenantEntity {

    @Column(name = "lote_id", nullable = false, updatable = false)
    private UUID loteId;

    @Column(name = "carga_id")
    private UUID cargaId;

    @Column(name = "tipo_gasto_id", nullable = false)
    private UUID tipoGastoId;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "monto", nullable = false, precision = 12, scale = 2)
    private BigDecimal monto;

    @Column(name = "descripcion", length = 250)
    private String descripcion;

    protected GastoVinculado() {
    }

    public GastoVinculado(UUID empresaId, UUID loteId) {
        setEmpresaId(empresaId);
        this.loteId = loteId;
    }

    public UUID getLoteId() {
        return loteId;
    }

    public UUID getCargaId() {
        return cargaId;
    }

    public void setCargaId(UUID cargaId) {
        this.cargaId = cargaId;
    }

    public UUID getTipoGastoId() {
        return tipoGastoId;
    }

    public void setTipoGastoId(UUID tipoGastoId) {
        this.tipoGastoId = tipoGastoId;
    }

    public LocalDate getFecha() {
        return fecha;
    }

    public void setFecha(LocalDate fecha) {
        this.fecha = fecha;
    }

    public BigDecimal getMonto() {
        return monto;
    }

    public void setMonto(BigDecimal monto) {
        this.monto = monto;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }
}
