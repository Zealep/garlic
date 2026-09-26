package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.shared.domain.AuditableEntity;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * Muestra representativa del lote (1..N) con sus % de calidad (2.1) y calibre (2.2).
 */
@Entity
@Table(name = "muestra")
public class Muestra extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "evaluacion_id", nullable = false, updatable = false)
    private EvaluacionLote evaluacion;

    @Column(name = "numero", nullable = false)
    private Short numero;

    @Column(name = "observacion")
    private String observacion;

    @ElementCollection
    @CollectionTable(name = "muestra_calidad", joinColumns = @JoinColumn(name = "muestra_id"))
    private Set<PorcentajeCalidad> calidad = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "muestra_calibre", joinColumns = @JoinColumn(name = "muestra_id"))
    private Set<PorcentajeCalibre> calibres = new HashSet<>();

    protected Muestra() {
    }

    Muestra(EvaluacionLote evaluacion, short numero) {
        this.evaluacion = evaluacion;
        this.numero = numero;
    }

    public UUID getId() {
        return id;
    }

    public EvaluacionLote getEvaluacion() {
        return evaluacion;
    }

    public short getNumero() {
        return numero;
    }

    public String getObservacion() {
        return observacion;
    }

    public void setObservacion(String observacion) {
        this.observacion = observacion;
    }

    public Set<PorcentajeCalidad> getCalidad() {
        return Set.copyOf(calidad);
    }

    public void reemplazarCalidad(Collection<PorcentajeCalidad> valores) {
        calidad.clear();
        calidad.addAll(valores);
    }

    public Set<PorcentajeCalibre> getCalibres() {
        return Set.copyOf(calibres);
    }

    public void reemplazarCalibres(Collection<PorcentajeCalibre> valores) {
        calibres.clear();
        calibres.addAll(valores);
    }
}
