package com.zealep.garlicbackend.evaluacion;

import com.zealep.garlicbackend.lote.Lote;
import com.zealep.garlicbackend.shared.domain.TenantEntity;
import com.zealep.garlicbackend.usuario.Usuario;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.hibernate.annotations.BatchSize;

/**
 * Punto 2 del protocolo: evaluacion de calidad del lote (agregado raiz).
 * Todo se registra por muestra: calidad, calibre, sensoriales (humedad, empaste, danos) y sanidad.
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

    /** Dictamen tras cerrar (null = pendiente). */
    @Enumerated(EnumType.STRING)
    @Column(name = "resultado", length = 15)
    private ResultadoEvaluacion resultado;

    @Column(name = "motivo_resultado", length = 500)
    private String motivoResultado;

    @Column(name = "fecha_resultado")
    private Instant fechaResultado;

    @OneToMany(mappedBy = "evaluacion", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("numero")
    @BatchSize(size = 50)
    private List<Muestra> muestras = new ArrayList<>();

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

    /** Registra (o corrige) el dictamen; solo en evaluaciones cerradas. Null vuelve a "pendiente". */
    public void definirResultado(ResultadoEvaluacion resultado, String motivo) {
        if (isBorrador()) {
            throw new IllegalStateException("La evaluacion debe estar cerrada");
        }
        this.resultado = resultado;
        this.motivoResultado = resultado == null ? null : motivo;
        this.fechaResultado = resultado == null ? null : Instant.now();
    }

    public ResultadoEvaluacion getResultado() {
        return resultado;
    }

    public String getMotivoResultado() {
        return motivoResultado;
    }

    public Instant getFechaResultado() {
        return fechaResultado;
    }

    // ---------------------------------------------------------------- muestras

    public Optional<Muestra> muestra(short numero) {
        return muestras.stream().filter(m -> m.getNumero() == numero).findFirst();
    }

    public Optional<Muestra> muestra(UUID id) {
        return muestras.stream().filter(m -> id.equals(m.getId())).findFirst();
    }

    /** Muestra nueva con el id de la app (o uno nuevo si no viene). */
    public Muestra agregarMuestra(UUID id, short numero) {
        Muestra nueva = new Muestra(this, id == null ? UUID.randomUUID() : id, numero);
        muestras.add(nueva);
        return nueva;
    }

    public void quitarMuestra(Muestra muestra) {
        muestras.remove(muestra);
    }

    public List<Muestra> getMuestras() {
        return List.copyOf(muestras);
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
