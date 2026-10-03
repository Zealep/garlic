package com.zealep.garlicbackend.compra.dto;

import java.util.List;
import java.util.UUID;

/** Todo el punto 3 de un lote: precio, cargas, gastos, pagos, comprobantes y balance. */
public record CompraLoteResponse(
        UUID loteId,
        FijacionResponse fijacion,
        List<CargaResponse> cargas,
        List<GastoResponse> gastos,
        List<PagoResponse> pagos,
        List<ComprobanteResponse> comprobantes,
        ResumenCompra resumen) {
}
