package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.lote.Lote;
import com.zealep.garlicbackend.shared.domain.TenantEntity;
import com.zealep.garlicbackend.usuario.Usuario;
import jakarta.persistence.CascadeType;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;

/**
 * Punto 2 del protocolo: evaluacion de calidad del lote (agregado raiz).
 * Calidad y calibre se registran por muestra; humedad, empaste, danos y sanidad por evaluacion.
 */
@Entity
@Table(name = "evaluacion_lote")
public class EvaluacionLote extends TenantEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "lote_id", nullable = false, updatable = false)
    private Lote lote;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "evaluador_id", nullable = false)
    private Usuario evaluador;

    @Column(name = "fecha_evaluacion", nullable = false)
    private LocalDate fechaEvaluacion;

    @Column(name = "observacion")
    private String observacion;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    private EstadoEvaluacion estado = EstadoEvaluacion.BORRADOR;

    @OneToMany(mappedBy = "evaluacion", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("numero")
    @BatchSize(size = 50)
    private List<Muestra> muestras = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "evaluacion_humedad", joinColumns = @JoinColumn(name = "evaluacion_id"))
    private Set<HumedadObservada> humedad = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "evaluacion_empaste", joinColumns = @JoinColumn(name = "evaluacion_id"))
    @Column(name = "tipo_empaste_id", nullable = false)
    private Set<UUID> empastes = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "evaluacion_dano", joinColumns = @JoinColumn(name = "evaluacion_id"))
    @Column(name = "tipo_dano_id", nullable = false)
    private Set<UUID> danos = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "evaluacion_sanidad", joinColumns = @JoinColumn(name = "evaluacion_id"))
    private Set<SanidadObservada> sanidad = new HashSet<>();

    protected EvaluacionLote() {
    }

    public EvaluacionLote(UUID empresaId, Lote lote) {
        setEmpresaId(empresaId);
        this.lote = lote;
    }

    public boolean isBorrador() {
        return estado == EstadoEvaluacion.BORRADOR;
    }

    public void cerrar() {
        this.estado = EstadoEvaluacion.CERRADA;
    }

    // ---------------------------------------------------------------- muestras

    public Optional<Muestra> muestra(short numero) {
        return muestras.stream().filter(m -> m.getNumero() == numero).findFirst();
    }

    /** Devuelve la muestra con ese numero, creandola si no existe (se actualiza en sitio para conservar sus evidencias). */
    public Muestra muestraONueva(short numero) {
        return muestra(numero).orElseGet(() -> {
            Muestra nueva = new Muestra(this, numero);
            muestras.add(nueva);
            return nueva;
        });
    }

    public void quitarMuestra(Muestra muestra) {
        muestras.remove(muestra);
    }

    public List<Muestra> getMuestras() {
        return List.copyOf(muestras);
    }

    // ---------------------------------------------------------------- factores por evaluacion

    public void reemplazarHumedad(Collection<HumedadObservada> valores) {
        humedad.clear();
        humedad.addAll(valores);
    }

    public void reemplazarEmpastes(Collection<UUID> valores) {
        empastes.clear();
        empastes.addAll(valores);
    }

    public void reemplazarDanos(Collection<UUID> valores) {
        danos.clear();
        danos.addAll(valores);
    }

    public void reemplazarSanidad(Collection<SanidadObservada> valores) {
        sanidad.clear();
        sanidad.addAll(valores);
    }

    public Set<HumedadObservada> getHumedad() {
        return Set.copyOf(humedad);
    }

    public Set<UUID> getEmpastes() {
        return Set.copyOf(empastes);
    }

    public Set<UUID> getDanos() {
        return Set.copyOf(danos);
    }

    public Set<SanidadObservada> getSanidad() {
        return Set.copyOf(sanidad);
    }

    // ---------------------------------------------------------------- getters / setters

    public Lote getLote() {
        return lote;
    }

    public Usuario getEvaluador() {
        return evaluador;
    }

    public void setEvaluador(Usuario evaluador) {
        this.evaluador = evaluador;
    }

    public LocalDate getFechaEvaluacion() {
        return fechaEvaluacion;
    }

    public void setFechaEvaluacion(LocalDate fechaEvaluacion) {
        this.fechaEvaluacion = fechaEvaluacion;
    }

    public String getObservacion() {
        return observacion;
    }

    public void setObservacion(String observacion) {
        this.observacion = observacion;
    }

    public EstadoEvaluacion getEstado() {
        return estado;
    }
}
