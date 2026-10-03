package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Embeddable;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * Modulo de fijacion de precio del lote (uno por lote). Los precios calculados son una foto
 * tomada por el servidor al guardar, a partir de la evaluacion indicada.
 */
@Entity
@Table(name = "fijacion_precio")
public class FijacionPrecio extends TenantEntity {

    @Column(name = "lote_id", nullable = false, updatable = false)
    private UUID loteId;

    @Column(name = "evaluacion_id", nullable = false)
    private UUID evaluacionId;

    @Column(name = "gasto_llenado", nullable = false, precision = 10, scale = 4)
    private BigDecimal gastoLlenado = BigDecimal.ZERO;

    @Column(name = "precio_promedio", nullable = false, precision = 10, scale = 4)
    private BigDecimal precioPromedio;

    @Column(name = "precio_tecnico", nullable = false, precision = 10, scale = 4)
    private BigDecimal precioTecnico;

    @Column(name = "precio_pactado", precision = 10, scale = 4)
    private BigDecimal precioPactado;

    @Column(name = "fecha_pacto")
    private LocalDate fechaPacto;

    @Column(name = "observacion")
    private String observacion;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "fijacion_precio_clase", joinColumns = @JoinColumn(name = "fijacion_id"))
    private Set<PrecioClase> precios = new HashSet<>();

    protected FijacionPrecio() {
    }

    public FijacionPrecio(UUID empresaId, UUID loteId) {
        setEmpresaId(empresaId);
        this.loteId = loteId;
    }

    /** Precio base (S/ por kg) de una clase de calidad. */
    @Embeddable
    public record PrecioClase(
            @Column(name = "clase_calidad_id", nullable = false) UUID claseCalidadId,
            @Column(name = "precio_base", nullable = false, precision = 10, scale = 4) BigDecimal precioBase) {
    }

    public void reemplazarPrecios(Collection<PrecioClase> valores) {
        precios.retainAll(valores);
        precios.addAll(valores);
    }

    public UUID getLoteId() {
        return loteId;
    }

    public UUID getEvaluacionId() {
        return evaluacionId;
    }

    public void setEvaluacionId(UUID evaluacionId) {
        this.evaluacionId = evaluacionId;
    }

    public BigDecimal getGastoLlenado() {
        return gastoLlenado;
    }

    public void setGastoLlenado(BigDecimal gastoLlenado) {
        this.gastoLlenado = gastoLlenado;
    }

    public BigDecimal getPrecioPromedio() {
        return precioPromedio;
    }

    public BigDecimal getPrecioTecnico() {
        return precioTecnico;
    }

    public void setPreciosCalculados(BigDecimal precioPromedio, BigDecimal precioTecnico) {
        this.precioPromedio = precioPromedio;
        this.precioTecnico = precioTecnico;
    }

    public BigDecimal getPrecioPactado() {
        return precioPactado;
    }

    public void setPrecioPactado(BigDecimal precioPactado) {
        this.precioPactado = precioPactado;
    }

    public LocalDate getFechaPacto() {
        return fechaPacto;
    }

    public void setFechaPacto(LocalDate fechaPacto) {
        this.fechaPacto = fechaPacto;
    }

    public String getObservacion() {
        return observacion;
    }

    public void setObservacion(String observacion) {
        this.observacion = observacion;
    }

    public Set<PrecioClase> getPrecios() {
        return precios;
    }
}
