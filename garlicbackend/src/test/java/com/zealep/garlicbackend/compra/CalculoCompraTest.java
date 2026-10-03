package com.zealep.garlicbackend.compra;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Formulas del punto 3 con el ejemplo de la hoja "LOTE #XXX MODELO" del Excel.
 */
class CalculoCompraTest {

    private static final UUID PRIMERA = UUID.randomUUID();
    private static final UUID ABIERTOS = UUID.randomUUID();
    private static final Map<UUID, BigDecimal> PRECIOS = Map.of(PRIMERA, bd("3.4"), ABIERTOS, bd("1.4"));

    @Nested
    class FijacionDePrecio {

        @Test
        void promedioDeMuestras_menosGastoDeLlenado_comoElExcel() {
            var calidad = List.of(
                    Map.of(PRIMERA, bd("80"), ABIERTOS, bd("20")),
                    Map.of(PRIMERA, bd("85"), ABIERTOS, bd("15")),
                    Map.of(PRIMERA, bd("75"), ABIERTOS, bd("25")));

            var f = CalculoCompra.fijacion(PRECIOS, calidad, bd("0.30"));

            assertThat(f.precioPorMuestra()).usingElementComparator(BigDecimal::compareTo)
                    .containsExactly(bd("3.00"), bd("3.10"), bd("2.90"));
            assertThat(f.precioPromedio()).isEqualByComparingTo("3.00");
            assertThat(f.precioTecnico()).isEqualByComparingTo("2.70");
        }

        @Test
        void claseSinPrecioBase_cuentaComoCero() {
            assertThat(CalculoCompra.precioMuestra(Map.of(PRIMERA, bd("3.4")), Map.of(PRIMERA, bd("80"), ABIERTOS, bd("20"))))
                    .isEqualByComparingTo("2.72");
        }

        @Test
        void sinMuestras_promedioCero() {
            assertThat(CalculoCompra.fijacion(PRECIOS, List.of(), null).precioTecnico()).isEqualByComparingTo("0");
        }
    }

    @Nested
    class Balance {

        private final List<CalculoCompra.LineaCarga> cargas = List.of(
                CalculoCompra.carga(bd("15000"), bd("2.8"), bd("1")),
                CalculoCompra.carga(bd("15000"), bd("2.8"), bd("1")));
        private final List<BigDecimal> gastos = List.of(bd("1800"), bd("30"), bd("900"), bd("70"));

        @Test
        void carga_descuentaElDestare() {
            var l = cargas.getFirst();
            assertThat(l.destareKg()).isEqualByComparingTo("150");
            assertThat(l.kgNeto()).isEqualByComparingTo("14850");
            assertThat(l.importe()).isEqualByComparingTo("42000");
            assertThat(l.descuentoDestare()).isEqualByComparingTo("420");
            assertThat(l.total()).isEqualByComparingTo("41580");
        }

        @Test
        void ejemploDelExcel_totalPacking_yCostosUnitarios() {
            var b = CalculoCompra.balance(cargas, gastos, List.of());

            assertThat(b.kgCargados()).isEqualByComparingTo("30000");
            assertThat(b.destareKg()).isEqualByComparingTo("300");
            assertThat(b.kgNetos()).isEqualByComparingTo("29700");
            assertThat(b.totalMp()).isEqualByComparingTo("83160");          // pago final al agricultor
            assertThat(b.gastosVinculados()).isEqualByComparingTo("2800");
            assertThat(b.costoPacking()).isEqualByComparingTo("85960");     // TOTAL S/ - PACKING
            assertThat(b.cuMp()).isEqualByComparingTo("2.8000");
            assertThat(b.cuGastos()).isEqualByComparingTo("0.0943");
            assertThat(b.cuPacking()).isEqualByComparingTo("2.8943");
            assertThat(b.saldo()).isEqualByComparingTo("83160");
            assertThat(b.estadoPago()).isEqualTo(EstadoPago.POR_PAGAR);
        }

        @Test
        void saldo_esTotalMpMenosPagos() {
            var b = CalculoCompra.balance(cargas, gastos, List.of(bd("50000"), bd("3160")));
            assertThat(b.totalPagado()).isEqualByComparingTo("53160");
            assertThat(b.saldo()).isEqualByComparingTo("30000");
            assertThat(b.estadoPago()).isEqualTo(EstadoPago.PARCIAL);
        }

        @Test
        void estadosDePago() {
            assertThat(CalculoCompra.balance(cargas, gastos, List.of(bd("83160"))).estadoPago()).isEqualTo(EstadoPago.PAGADO);
            assertThat(CalculoCompra.balance(cargas, gastos, List.of(bd("90000"))).estadoPago()).isEqualTo(EstadoPago.PAGADO_DE_MAS);
            assertThat(CalculoCompra.balance(List.of(), List.of(), List.of()).estadoPago()).isEqualTo(EstadoPago.SIN_COMPRAS);
            // adelanto antes de la primera carga
            assertThat(CalculoCompra.balance(List.of(), List.of(), List.of(bd("1000"))).estadoPago()).isEqualTo(EstadoPago.PAGADO_DE_MAS);
        }

        @Test
        void sinCargas_noHayCostoUnitario() {
            var b = CalculoCompra.balance(List.of(), gastos, List.of());
            assertThat(b.cuMp()).isNull();
            assertThat(b.cuPacking()).isNull();
            assertThat(b.costoPacking()).isEqualByComparingTo("2800");
        }
    }

    private static BigDecimal bd(String v) {
        return new BigDecimal(v);
    }
}
