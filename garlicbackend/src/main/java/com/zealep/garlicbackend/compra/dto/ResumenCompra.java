package com.zealep.garlicbackend.compra.dto;

import com.zealep.garlicbackend.compra.CalculoCompra;
import com.zealep.garlicbackend.compra.EstadoPago;
import java.math.BigDecimal;

/**
 * Balance del lote (3.4 a 3.6 del protocolo).
 *
 * @param totalMp      pago final al agricultor = suma de totales de carga
 * @param saldo        totalMp - totalPagado (negativo = adelanto excedente)
 * @param costoPacking totalMp + gastos vinculados (materia prima puesta en packing)
 * @param cuMp         costo unitario de la materia prima (S/ por kg neto); null sin cargas
 * @param cuPacking    costo unitario puesto en packing (S/ por kg neto); null sin cargas
 */
public record ResumenCompra(
        int nroCargas,
        int cantidadEmpaques,
        BigDecimal kgCargados,
        BigDecimal destareKg,
        BigDecimal kgNetos,
        BigDecimal totalMp,
        BigDecimal totalPagado,
        BigDecimal saldo,
        EstadoPago estadoPago,
        BigDecimal gastosVinculados,
        BigDecimal costoPacking,
        BigDecimal cuMp,
        BigDecimal cuGastos,
        BigDecimal cuPacking) {

    public static ResumenCompra of(int nroCargas, int cantidadEmpaques, CalculoCompra.Balance b) {
        return new ResumenCompra(nroCargas, cantidadEmpaques, b.kgCargados(), b.destareKg(), b.kgNetos(), b.totalMp(),
                b.totalPagado(), b.saldo(), b.estadoPago(), b.gastosVinculados(), b.costoPacking(), b.cuMp(),
                b.cuGastos(), b.cuPacking());
    }
}
