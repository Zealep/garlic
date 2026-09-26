package com.zealep.garlicbackend.lote;

import java.util.UUID;

/**
 * Filtros opcionales del listado de lotes.
 *
 * @param q texto a buscar en codigo, zona o nombre/documento del agricultor
 */
public record LoteFiltro(String q, UUID campaniaId, EstadoLote estado, UUID agricultorId, UUID proveedorId) {
}
