package com.zealep.garlicbackend.lote;

import com.zealep.garlicbackend.catalogo.campania.Campania;
import com.zealep.garlicbackend.catalogo.localidad.Localidad;
import com.zealep.garlicbackend.catalogo.tipocompra.TipoCompra;
import com.zealep.garlicbackend.catalogo.variedad.Variedad;
import com.zealep.garlicbackend.shared.domain.TenantEntity;
import com.zealep.garlicbackend.tercero.agricultor.Agricultor;
import com.zealep.garlicbackend.tercero.persona.Persona;
import com.zealep.garlicbackend.tercero.proveedor.Proveedor;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Locale;
import java.util.UUID;
import org.hibernate.annotations.Generated;
import org.hibernate.generator.EventType;

/**
 * Punto 1 del protocolo: identificacion del lote comprado en campo.
 */
@Entity
@Table(name = "lote")
public class Lote extends TenantEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "campania_id", nullable = false)
    private Campania campania;

    /** Se toma de la campania; se guarda para consultas por cultivo. */
    @Column(name = "cultivo_id", nullable = false)
    private UUID cultivoId;

    @Column(name = "codigo", nullable = false, length = 30)
    private String codigo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "variedad_id", nullable = false)
    private Variedad variedad;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "agricultor_id", nullable = false)
    private Agricultor agricultor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "proveedor_id")
    private Proveedor proveedor;

    /** DNI LC: persona a cuyo nombre se emite la liquidacion de compra. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "titular_liquidacion_id")
    private Persona titularLiquidacion;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "localidad_id", nullable = false)
    private Localidad localidad;

    @Column(name = "zona", nullable = false, length = 50)
    private String zona;

    /** Columna generada por la base; clave del indice antiduplicados. */
    @Generated(event = {EventType.INSERT, EventType.UPDATE})
    @Column(name = "zona_normalizada", insertable = false, updatable = false, length = 50)
    private String zonaNormalizada;

    @Column(name = "latitud", precision = 9, scale = 6)
    private BigDecimal latitud;

    @Column(name = "longitud", precision = 9, scale = 6)
    private BigDecimal longitud;

    @Column(name = "maps_url")
    private String mapsUrl;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tipo_compra_id", nullable = false)
    private TipoCompra tipoCompra;

    @Column(name = "fecha_arrancado")
    private LocalDate fechaArrancado;

    @Column(name = "fecha_corte")
    private LocalDate fechaCorte;

    @Column(name = "fecha_carga")
    private LocalDate fechaCarga;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    private EstadoLote estado = EstadoLote.ACTIVO;

    /** Misma regla que la columna generada zona_normalizada de la base. */
    public static String normalizarZona(String zona) {
        return zona == null ? null : zona.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
    }

    public void anular() {
        this.estado = EstadoLote.ANULADO;
    }

    public boolean isActivo() {
        return estado == EstadoLote.ACTIVO;
    }

    public Campania getCampania() {
        return campania;
    }

    public void setCampania(Campania campania) {
        this.campania = campania;
        this.cultivoId = campania == null ? null : campania.getCultivoId();
    }

    public UUID getCultivoId() {
        return cultivoId;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo == null ? null : codigo.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
    }

    public Variedad getVariedad() {
        return variedad;
    }

    public void setVariedad(Variedad variedad) {
        this.variedad = variedad;
    }

    public Agricultor getAgricultor() {
        return agricultor;
    }

    public void setAgricultor(Agricultor agricultor) {
        this.agricultor = agricultor;
    }

    public Proveedor getProveedor() {
        return proveedor;
    }

    public void setProveedor(Proveedor proveedor) {
        this.proveedor = proveedor;
    }

    public Persona getTitularLiquidacion() {
        return titularLiquidacion;
    }

    public void setTitularLiquidacion(Persona titularLiquidacion) {
        this.titularLiquidacion = titularLiquidacion;
    }

    public Localidad getLocalidad() {
        return localidad;
    }

    public void setLocalidad(Localidad localidad) {
        this.localidad = localidad;
    }

    public String getZona() {
        return zona;
    }

    public void setZona(String zona) {
        this.zona = zona == null ? null : zona.trim();
    }

    public String getZonaNormalizada() {
        return zonaNormalizada;
    }

    public BigDecimal getLatitud() {
        return latitud;
    }

    public void setLatitud(BigDecimal latitud) {
        this.latitud = latitud;
    }

    public BigDecimal getLongitud() {
        return longitud;
    }

    public void setLongitud(BigDecimal longitud) {
        this.longitud = longitud;
    }

    public String getMapsUrl() {
        return mapsUrl;
    }

    public void setMapsUrl(String mapsUrl) {
        this.mapsUrl = mapsUrl;
    }

    public TipoCompra getTipoCompra() {
        return tipoCompra;
    }

    public void setTipoCompra(TipoCompra tipoCompra) {
        this.tipoCompra = tipoCompra;
    }

    public LocalDate getFechaArrancado() {
        return fechaArrancado;
    }

    public void setFechaArrancado(LocalDate fechaArrancado) {
        this.fechaArrancado = fechaArrancado;
    }

    public LocalDate getFechaCorte() {
        return fechaCorte;
    }

    public void setFechaCorte(LocalDate fechaCorte) {
        this.fechaCorte = fechaCorte;
    }

    public LocalDate getFechaCarga() {
        return fechaCarga;
    }

    public void setFechaCarga(LocalDate fechaCarga) {
        this.fechaCarga = fechaCarga;
    }

    public EstadoLote getEstado() {
        return estado;
    }
}
