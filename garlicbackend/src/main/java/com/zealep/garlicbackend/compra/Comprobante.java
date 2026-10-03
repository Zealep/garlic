package com.zealep.garlicbackend.compra;

import com.zealep.garlicbackend.shared.domain.TenantEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Foto de respaldo de una carga (ticket de balanza), un pago (voucher) o un gasto (recibo).
 */
@Entity
@Table(name = "comprobante")
public class Comprobante extends TenantEntity {

    @Column(name = "lote_id", nullable = false, updatable = false)
    private UUID loteId;

    @Enumerated(EnumType.STRING)
    @Column(name = "entidad", nullable = false, length = 10, updatable = false)
    private EntidadComprobante entidad;

    @Column(name = "entidad_id", nullable = false, updatable = false)
    private UUID entidadId;

    /** Clave del archivo en el StorageService. */
    @Column(name = "url_archivo", nullable = false)
    private String urlArchivo;

    @Column(name = "fecha_captura")
    private Instant fechaCaptura;

    protected Comprobante() {
    }

    public Comprobante(UUID empresaId, UUID loteId, EntidadComprobante entidad, UUID entidadId, String urlArchivo,
            Instant fechaCaptura) {
        setEmpresaId(empresaId);
        this.loteId = loteId;
        this.entidad = entidad;
        this.entidadId = entidadId;
        this.urlArchivo = urlArchivo;
        this.fechaCaptura = fechaCaptura;
    }

    public UUID getLoteId() {
        return loteId;
    }

    public EntidadComprobante getEntidad() {
        return entidad;
    }

    public UUID getEntidadId() {
        return entidadId;
    }

    public String getUrlArchivo() {
        return urlArchivo;
    }

    public Instant getFechaCaptura() {
        return fechaCaptura;
    }
}
