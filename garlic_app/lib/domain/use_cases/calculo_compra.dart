/// Fórmulas del punto 3 (las mismas de `CalculoCompra.java` en el backend), para calcular en vivo
/// y sin conexión. El servidor recalcula y es la fuente de verdad.
/// Montos a 2 decimales; precios por kg y costos unitarios a 4.
abstract final class CalculoCompra {
  /// Precio de una muestra = Σ precio base × % / 100. Una clase sin precio cuenta como 0.
  static double precioMuestra(Map<String, double> preciosBase, Map<String, double> calidad) {
    var total = 0.0;
    calidad.forEach((clase, pct) => total += (preciosBase[clase] ?? 0) * pct);
    return redondear(total / 100, 4);
  }

  /// Precio técnico = promedio de los precios por muestra − gasto de llenado.
  static ResultadoFijacion fijacion(
    Map<String, double> preciosBase,
    List<Map<String, double>> calidadMuestras,
    double gastoLlenado,
  ) {
    final porMuestra = calidadMuestras.map((c) => precioMuestra(preciosBase, c)).toList();
    final promedio = porMuestra.isEmpty ? 0.0 : redondear(porMuestra.reduce((a, b) => a + b) / porMuestra.length, 4);
    return ResultadoFijacion(
      precioPorMuestra: porMuestra,
      precioPromedio: promedio,
      precioTecnico: redondear(promedio - gastoLlenado, 4),
    );
  }

  /// destare_kg = kg × destare% / 100; kg neto = kg − destare; total = kg neto × precio.
  static LineaCarga carga(double kg, double precioKg, double destarePct) {
    final destareKg = redondear(kg * destarePct / 100, 2);
    final importe = redondear(kg * precioKg, 2);
    final descuento = redondear(destareKg * precioKg, 2);
    return LineaCarga(
      kg: kg,
      destareKg: destareKg,
      kgNeto: redondear(kg - destareKg, 2),
      importe: importe,
      descuentoDestare: descuento,
      total: redondear(importe - descuento, 2),
    );
  }

  /// Total MP (pago final al agricultor), saldo, costo puesto en packing y costos unitarios por kg neto.
  static BalanceCompra balance(List<LineaCarga> cargas, List<double> gastos, List<double> pagos) {
    double suma(Iterable<double> v) => v.fold(0, (a, b) => a + b);
    final kgNetos = redondear(suma(cargas.map((c) => c.kgNeto)), 2);
    final totalMp = redondear(suma(cargas.map((c) => c.total)), 2);
    final pagado = redondear(suma(pagos), 2);
    final gastosVinculados = redondear(suma(gastos), 2);
    final costoPacking = redondear(totalMp + gastosVinculados, 2);
    double? unitario(double total) => kgNetos == 0 ? null : redondear(total / kgNetos, 4);
    return BalanceCompra(
      kgCargados: redondear(suma(cargas.map((c) => c.kg)), 2),
      destareKg: redondear(suma(cargas.map((c) => c.destareKg)), 2),
      kgNetos: kgNetos,
      totalMp: totalMp,
      totalPagado: pagado,
      saldo: redondear(totalMp - pagado, 2),
      estadoPago: estadoPago(sinCargas: cargas.isEmpty, totalMp: totalMp, pagado: pagado),
      gastosVinculados: gastosVinculados,
      costoPacking: costoPacking,
      cuMp: unitario(totalMp),
      cuGastos: unitario(gastosVinculados),
      cuPacking: unitario(costoPacking),
    );
  }

  static EstadoPago estadoPago({required bool sinCargas, required double totalMp, required double pagado}) {
    if (sinCargas) return pagado > 0 ? EstadoPago.pagadoDeMas : EstadoPago.sinCompras;
    if (pagado > totalMp) return EstadoPago.pagadoDeMas;
    if (pagado == totalMp) return EstadoPago.pagado;
    return pagado == 0 ? EstadoPago.porPagar : EstadoPago.parcial;
  }

  static double redondear(double v, int decimales) => double.parse(v.toStringAsFixed(decimales));
}

class ResultadoFijacion {
  const ResultadoFijacion({required this.precioPorMuestra, required this.precioPromedio, required this.precioTecnico});

  final List<double> precioPorMuestra;
  final double precioPromedio;
  final double precioTecnico;
}

class LineaCarga {
  const LineaCarga({
    required this.kg,
    required this.destareKg,
    required this.kgNeto,
    required this.importe,
    required this.descuentoDestare,
    required this.total,
  });

  final double kg;
  final double destareKg;
  final double kgNeto;

  /// kg × precio.
  final double importe;

  /// destare (kg) × precio.
  final double descuentoDestare;

  /// importe − descuento: lo que se paga por la carga.
  final double total;
}

enum EstadoPago {
  sinCompras('Sin compras'),
  porPagar('Por pagar'),
  parcial('Pago parcial'),
  pagado('Pagado'),
  pagadoDeMas('Pagado de más');

  const EstadoPago(this.etiqueta);

  final String etiqueta;
}

class BalanceCompra {
  const BalanceCompra({
    required this.kgCargados,
    required this.destareKg,
    required this.kgNetos,
    required this.totalMp,
    required this.totalPagado,
    required this.saldo,
    required this.estadoPago,
    required this.gastosVinculados,
    required this.costoPacking,
    required this.cuMp,
    required this.cuGastos,
    required this.cuPacking,
  });

  final double kgCargados;
  final double destareKg;
  final double kgNetos;

  /// Pago final al agricultor: Σ totales de carga.
  final double totalMp;
  final double totalPagado;

  /// totalMp − pagado (negativo = adelanto excedente).
  final double saldo;
  final EstadoPago estadoPago;
  final double gastosVinculados;

  /// Materia prima puesta en packing: totalMp + gastos vinculados.
  final double costoPacking;

  /// S/ por kg neto (null sin cargas).
  final double? cuMp;
  final double? cuGastos;
  final double? cuPacking;
}
