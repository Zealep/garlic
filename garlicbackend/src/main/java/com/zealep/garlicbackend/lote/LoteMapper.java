package com.zealep.garlicbackend.lote;

import com.zealep.garlicbackend.lote.LoteResponse.CatalogoRef;
import com.zealep.garlicbackend.lote.LoteResponse.PersonaRef;
import com.zealep.garlicbackend.tercero.persona.Persona;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Mapeo manual: el lote combina referencias de varios modulos en una respuesta resumida.
 */
@Component
public class LoteMapper {

    public LoteResponse toResponse(Lote lote) {
        return new LoteResponse(
                lote.getId(),
                lote.getCodigo(),
                lote.getEstado(),
                new CatalogoRef(lote.getCampania().getId(), lote.getCampania().getCodigo(), null),
                lote.getCultivoId(),
                new CatalogoRef(lote.getVariedad().getId(), lote.getVariedad().getCodigo(), lote.getVariedad().getNombre()),
                persona(lote.getAgricultor().getId(), lote.getAgricultor().getPersona()),
                lote.getProveedor() == null ? null : persona(lote.getProveedor().getId(), lote.getProveedor().getPersona()),
                lote.getTitularLiquidacion() == null ? null
                        : persona(lote.getTitularLiquidacion().getId(), lote.getTitularLiquidacion()),
                new CatalogoRef(lote.getLocalidad().getId(), null, lote.getLocalidad().getNombre()),
                lote.getZona(),
                lote.getLatitud(),
                lote.getLongitud(),
                lote.getMapsUrl(),
                new CatalogoRef(lote.getTipoCompra().getId(), lote.getTipoCompra().getCodigo(), lote.getTipoCompra().getNombre()),
                lote.getFechaArrancado(),
                lote.getFechaCorte(),
                lote.getFechaCarga(),
                lote.getCreatedAt(),
                lote.getUpdatedAt());
    }

    private static PersonaRef persona(UUID id, Persona p) {
        return new PersonaRef(id, p.getTipoDocumento(), p.getNumeroDocumento(), p.getNombres());
    }
}
