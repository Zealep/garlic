package com.zealep.garlicbackend.compra;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Formulas del punto 3 (ver docs/modelo-datos/02-compra-lote.md). Funciones puras: la app replica las mismas.
 * Montos a 2 decimales; precios por kg y costos unitarios a 4 (HALF_UP).
 */
public final class CalculoCompra {

    private static final BigDecimal CIEN = BigDecimal.valueOf(100);
    private static final int ESCALA_PRECIO = 4;
    private static final int ESCALA_MONTO = 2;

    private CalculoCompra() {
    }

    // ------------------------------------------------------------ fijacion de precio

    /** Precio de una muestra = suma(precio base de la clase x % de la clase / 100). Sin precio base cuenta como 0. */
    public static BigDecimal precioMuestra(Map<UUID, BigDecimal> preciosBase, Map<UUID, BigDecimal> calidad) {
        BigDecimal total = BigDecimal.ZERO;
        for (var e : calidad.entrySet()) {
            BigDecimal precio = preciosBase.getOrDefault(e.getKey(), BigDecimal.ZERO);
            total = total.add(precio.multiply(e.getValue()));
        }
        return total.divide(CIEN, ESCALA_PRECIO, RoundingMode.HALF_UP);
    }

    /**
     * Precio tecnico = promedio de los precios por muestra - gasto de llenado.
     *
     * @param calidadMuestras % de calidad por clase de cada muestra
     */
    public static Fijacion fijacion(Map<UUID, BigDecimal> preciosBase, List<Map<UUID, BigDecimal>> calidadMuestras,
            BigDecimal gastoLlenado) {
        List<BigDecimal> porMuestra = calidadMuestras.stream().map(c -> precioMuestra(preciosBase, c)).toList();
        BigDecimal promedio = porMuestra.isEmpty()
                ? BigDecimal.ZERO.setScale(ESCALA_PRECIO)
                : suma(porMuestra).divide(BigDecimal.valueOf(porMuestra.size()), ESCALA_PRECIO, RoundingMode.HALF_UP);
        BigDecimal llenado = gastoLlenado == null ? BigDecimal.ZERO : gastoLlenado;
        BigDecimal tecnico = promedio.subtract(llenado).setScale(ESCALA_PRECIO, RoundingMode.HALF_UP);
        return new Fijacion(porMuestra, promedio, tecnico);
    }

    public record Fijacion(List<BigDecimal> precioPorMuestra, BigDecimal precioPromedio, BigDecimal precioTecnico) {
    }

    // ------------------------------------------------------------ carga (camion)

    /** destare_kg = kg x destare% / 100; kg_neto = kg - destare_kg; total = kg_neto x precio. */
    public static LineaCarga carga(BigDecimal kg, BigDecimal precioKg, BigDecimal destarePct) {
        BigDecimal destareKg = kg.multiply(destarePct).divide(CIEN, ESCALA_MONTO, RoundingMode.HALF_UP);
        BigDecimal kgNeto = kg.subtract(destareKg);
        BigDecimal importe = monto(kg.multiply(precioKg));
        BigDecimal descuento = monto(destareKg.multiply(precioKg));
        return new LineaCarga(kg, destareKg, kgNeto, importe, descuento, importe.subtract(descuento));
    }

    /**
     * @param importe          kg x precio
     * @param descuentoDestare destare_kg x precio
     * @param total            importe - descuento = lo que se paga por la carga
     */
    public record LineaCarga(BigDecimal kg, BigDecimal destareKg, BigDecimal kgNeto, BigDecimal importe,
            BigDecimal descuentoDestare, BigDecimal total) {
    }

    // ------------------------------------------------------------ balance

    /**
     * total MP = suma de totales de carga (pago final al agricultor); saldo = total MP - pagos;
     * costo en packing = total MP + gastos vinculados; costos unitarios sobre kg netos.
     */
    public static Balance balance(Collection<LineaCarga> cargas, Collection<BigDecimal> gastos, Collection<BigDecimal> pagos) {
        BigDecimal kg = suma(cargas.stream().map(LineaCarga::kg).toList());
        BigDecimal destare = suma(cargas.stream().map(LineaCarga::destareKg).toList());
        BigDecimal kgNetos = suma(cargas.stream().map(LineaCarga::kgNeto).toList());
        BigDecimal totalMp = monto(suma(cargas.stream().map(LineaCarga::total).toList()));
        BigDecimal pagado = monto(suma(pagos));
        BigDecimal gastosVinculados = monto(suma(gastos));
        BigDecimal saldo = totalMp.subtract(pagado);
        BigDecimal costoPacking = totalMp.add(gastosVinculados);
        return new Balance(kg, destare, kgNetos, totalMp, pagado, saldo, estadoPago(cargas.isEmpty(), totalMp, pagado),
                gastosVinculados, costoPacking,
                unitario(totalMp, kgNetos), unitario(gastosVinculados, kgNetos), unitario(costoPacking, kgNetos));
    }

    static EstadoPago estadoPago(boolean sinCargas, BigDecimal totalMp, BigDecimal pagado) {
        int cmp = pagado.compareTo(totalMp);
        if (sinCargas) {
            return pagado.signum() > 0 ? EstadoPago.PAGADO_DE_MAS : EstadoPago.SIN_COMPRAS;
        }
        if (cmp > 0) {
            return EstadoPago.PAGADO_DE_MAS;
        }
        if (cmp == 0) {
            return EstadoPago.PAGADO;
        }
        return pagado.signum() == 0 ? EstadoPago.POR_PAGAR : EstadoPago.PARCIAL;
    }

    /**
     * @param saldo total MP - pagado (negativo = se adelanto de mas)
     * @param cuMp  costo unitario de la materia prima (S/ por kg neto)
     * @param cuPacking costo unitario puesto en packing (MP + gastos vinculados, S/ por kg neto)
     */
    public record Balance(BigDecimal kgCargados, BigDecimal destareKg, BigDecimal kgNetos, BigDecimal totalMp,
            BigDecimal totalPagado, BigDecimal saldo, EstadoPago estadoPago, BigDecimal gastosVinculados,
            BigDecimal costoPacking, BigDecimal cuMp, BigDecimal cuGastos, BigDecimal cuPacking) {
    }

    // ------------------------------------------------------------ util

    private static BigDecimal unitario(BigDecimal total, BigDecimal kg) {
        return kg.signum() == 0 ? null : total.divide(kg, ESCALA_PRECIO, RoundingMode.HALF_UP);
    }

    private static BigDecimal monto(BigDecimal v) {
        return v.setScale(ESCALA_MONTO, RoundingMode.HALF_UP);
    }

    private static BigDecimal suma(Collection<BigDecimal> valores) {
        return valores.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
