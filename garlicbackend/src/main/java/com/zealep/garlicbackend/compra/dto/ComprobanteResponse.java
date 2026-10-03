package com.zealep.garlicbackend.compra.dto;

import com.zealep.garlicbackend.compra.Comprobante;
import com.zealep.garlicbackend.compra.EntidadComprobante;
import java.time.Instant;
import java.util.UUID;

/** @param url ruta para descargar la foto */
public record ComprobanteResponse(UUID id, UUID loteId, EntidadComprobante entidad, UUID entidadId, String url,
        Instant fechaCaptura, Instant createdAt) {

    public static ComprobanteResponse from(Comprobante c) {
        return new ComprobanteResponse(c.getId(), c.getLoteId(), c.getEntidad(), c.getEntidadId(),
                "/api/v1/comprobantes/" + c.getId() + "/archivo", c.getFechaCaptura(), c.getCreatedAt());
    }
}
