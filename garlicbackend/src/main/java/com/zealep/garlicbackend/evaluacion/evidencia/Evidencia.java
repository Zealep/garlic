package com.zealep.garlicbackend.evaluacion.evidencia;

import com.zealep.garlicbackend.evaluacion.EvaluacionLote;
import com.zealep.garlicbackend.evaluacion.Muestra;
import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Evidencia fotografica de una evaluacion; opcionalmente de una muestra y de un factor.
 */
@Entity
@Table(name = "evidencia")
public class Evidencia extends TenantEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "evaluacion_id", nullable = false, updatable = false)
    private EvaluacionLote evaluacion;

    /** Null = evidencia general de la evaluacion. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "muestra_id", updatable = false)
    private Muestra muestra;

    @Enumerated(EnumType.STRING)
    @Column(name = "factor", length = 20)
    private FactorEvidencia factor;

    /** Clave del archivo en el {@link com.zealep.garlicbackend.shared.storage.StorageService}. */
    @Column(name = "url_archivo", nullable = false)
    private String urlArchivo;

    @Column(name = "descripcion", length = 250)
    private String descripcion;

    @Column(name = "fecha_captura")
    private Instant fechaCaptura;

    protected Evidencia() {
    }

    public Evidencia(EvaluacionLote evaluacion, Muestra muestra, FactorEvidencia factor, String urlArchivo,
            String descripcion, Instant fechaCaptura) {
        setEmpresaId(evaluacion.getEmpresaId());
        this.evaluacion = evaluacion;
        this.muestra = muestra;
        this.factor = factor;
        this.urlArchivo = urlArchivo;
        this.descripcion = descripcion;
        this.fechaCaptura = fechaCaptura;
    }

    public EvaluacionLote getEvaluacion() {
        return evaluacion;
    }

    public Muestra getMuestra() {
        return muestra;
    }

    public FactorEvidencia getFactor() {
        return factor;
    }

    public String getUrlArchivo() {
        return urlArchivo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public Instant getFechaCaptura() {
        return fechaCaptura;
    }
}
