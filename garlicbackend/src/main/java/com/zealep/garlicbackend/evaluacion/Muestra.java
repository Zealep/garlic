package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.shared.domain.AuditableEntity;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import com.zealep.garlicbackend.shared.domain.AssignableUuid;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * Muestra representativa del lote (1..N): % de calidad (2.1) y calibre (2.2), sensoriales (humedad, empaste,
 * danos) y sanidad. El id lo puede asignar la app: asi la muestra conserva sus fotos al renumerarse.
 */
@Entity
@Table(name = "muestra")
public class Muestra extends AuditableEntity {

    @Id
    @AssignableUuid
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

    @ElementCollection
    @CollectionTable(name = "muestra_humedad", joinColumns = @JoinColumn(name = "muestra_id"))
    private Set<HumedadObservada> humedad = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "muestra_empaste", joinColumns = @JoinColumn(name = "muestra_id"))
    @Column(name = "tipo_empaste_id", nullable = false)
    private Set<UUID> empastes = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "muestra_dano", joinColumns = @JoinColumn(name = "muestra_id"))
    private Set<DanoObservado> danos = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "muestra_sanidad", joinColumns = @JoinColumn(name = "muestra_id"))
    private Set<SanidadObservada> sanidad = new HashSet<>();

    protected Muestra() {
    }

    Muestra(EvaluacionLote evaluacion, UUID id, short numero) {
        this.evaluacion = evaluacion;
        this.id = id;
        this.numero = numero;
    }

    void setNumero(short numero) {
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

    public Set<HumedadObservada> getHumedad() {
        return Set.copyOf(humedad);
    }

    public void reemplazarHumedad(Collection<HumedadObservada> valores) {
        humedad.clear();
        humedad.addAll(valores);
    }

    public Set<UUID> getEmpastes() {
        return Set.copyOf(empastes);
    }

    public void reemplazarEmpastes(Collection<UUID> valores) {
        empastes.clear();
        empastes.addAll(valores);
    }

    public Set<DanoObservado> getDanos() {
        return Set.copyOf(danos);
    }

    public void reemplazarDanos(Collection<DanoObservado> valores) {
        danos.clear();
        danos.addAll(valores);
    }

    public Set<SanidadObservada> getSanidad() {
        return Set.copyOf(sanidad);
    }

    public void reemplazarSanidad(Collection<SanidadObservada> valores) {
        sanidad.clear();
        sanidad.addAll(valores);
    }
}
