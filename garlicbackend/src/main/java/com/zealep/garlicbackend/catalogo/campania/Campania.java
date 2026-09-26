package com.zealep.garlicbackend.catalogo.campania;

import com.zealep.garlicbackend.catalogo.base.CatalogoEntity;
import jakarta.persistence.AttributeOverride;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.util.Locale;
import java.util.UUID;

@Entity
@Table(name = "campania")
@AttributeOverride(name = "activo", column = @Column(name = "activa", nullable = false))
public class Campania extends CatalogoEntity {

    @Column(name = "cultivo_id", nullable = false)
    private UUID cultivoId;

    @Column(name = "codigo", nullable = false, length = 20)
    private String codigo;

    @Column(name = "fecha_inicio")
    private LocalDate fechaInicio;

    @Column(name = "fecha_fin")
    private LocalDate fechaFin;

    public UUID getCultivoId() {
        return cultivoId;
    }

    public void setCultivoId(UUID cultivoId) {
        this.cultivoId = cultivoId;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo == null ? null : codigo.trim().toUpperCase(Locale.ROOT);
    }

    public LocalDate getFechaInicio() {
        return fechaInicio;
    }

    public void setFechaInicio(LocalDate fechaInicio) {
        this.fechaInicio = fechaInicio;
    }

    public LocalDate getFechaFin() {
        return fechaFin;
    }

    public void setFechaFin(LocalDate fechaFin) {
        this.fechaFin = fechaFin;
    }
}
