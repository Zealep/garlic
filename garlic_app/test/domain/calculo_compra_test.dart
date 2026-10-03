import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/catalogo.dart';
import 'package:garlic_app/domain/models/compra.dart';
import 'package:garlic_app/domain/use_cases/calculo_compra.dart';
import 'package:garlic_app/domain/use_cases/reglas_compra.dart';

const primera = 'c-primera';
const abiertos = 'c-abiertos';

/// % de calidad de las 3 muestras del lote modelo del Excel.
const calidadExcel = [
  {primera: 80.0, abiertos: 20.0},
  {primera: 85.0, abiertos: 15.0},
  {primera: 75.0, abiertos: 25.0},
];

Carga camion(String id) => Carga(id: id, fecha: DateTime(2025, 10, 20), kg: 15000, precioKg: 2.8, cantidadEmpaques: 375);

void main() {
  group('Fijación de precio (ejemplo del Excel)', () {
    test('precio por muestra, promedio y técnico = promedio − llenado', () {
      final f = FijacionPrecio(evaluacionId: 'ev', preciosBase: {primera: 3.4, abiertos: 1.4}, gastoLlenado: 0.3);
      final r = f.calcular(calidadExcel);
      expect(r.precioPorMuestra, [3.0, 3.1, 2.9]);
      expect(r.precioPromedio, 3.0);
      expect(r.precioTecnico, 2.7);
    });

    test('para pactar, cada clase presente necesita precio base', () {
      final clases = [const CatalogoItem(id: abiertos, codigo: 'ABIERTOS', nombre: 'ABIERTOS')];
      final f = FijacionPrecio(evaluacionId: 'ev', preciosBase: {primera: 3.4}, precioPactado: 2.8);
      expect(ReglasCompra.fijacion(f, calidadExcel, clases), contains('Abiertos'));
      f.precioPactado = null; // sin pactar se puede guardar el cálculo
      expect(ReglasCompra.fijacion(f, calidadExcel, clases), isNull);
    });

    test('ida y vuelta por JSON (formato del API)', () {
      final f = FijacionPrecio(
        evaluacionId: 'ev',
        preciosBase: {primera: 3.4},
        precioPactado: 2.8,
        fechaPacto: DateTime(2025, 10, 12),
      );
      final copia = FijacionPrecio.fromJson(f.toRequestJson());
      expect(copia.preciosBase, {primera: 3.4});
      expect(copia.precioPactado, 2.8);
      expect(f.toRequestJson()['fechaPacto'], '2025-10-12');
    });
  });

  group('Cargas y balance (ejemplo del Excel)', () {
    test('un camión descuenta el 1% de destare', () {
      final l = camion('c1').calculo;
      expect(l.destareKg, 150);
      expect(l.kgNeto, 14850);
      expect(l.importe, 42000);
      expect(l.descuentoDestare, 420);
      expect(l.total, 41580);
    });

    test('dos camiones + gastos: MP 83 160, packing 85 960, C.U. 2.80 y 2.8943', () {
      final compra = CompraLote(
        loteId: 'l',
        cargas: [camion('c1'), camion('c2')],
        gastos: [
          for (final (i, m) in [1800.0, 30.0, 900.0, 70.0].indexed)
            GastoVinculado(id: 'g$i', tipoGastoId: 't', fecha: DateTime(2025, 10, 20), monto: m),
        ],
        pagos: [Pago(id: 'p', fecha: DateTime(2025, 10, 21), condicionPagoId: 'cta', monto: 50000)],
      );
      final b = compra.balance;
      expect(b.kgNetos, 29700);
      expect(b.totalMp, 83160);
      expect(b.gastosVinculados, 2800);
      expect(b.costoPacking, 85960);
      expect(b.cuMp, 2.8);
      expect(b.cuPacking, 2.8943);
      expect(b.saldo, 33160);
      expect(b.estadoPago, EstadoPago.parcial);
      expect(compra.cantidadEmpaques, 750);
    });

    test('estados de pago', () {
      expect(CalculoCompra.estadoPago(sinCargas: true, totalMp: 0, pagado: 0), EstadoPago.sinCompras);
      expect(CalculoCompra.estadoPago(sinCargas: true, totalMp: 0, pagado: 500), EstadoPago.pagadoDeMas);
      expect(CalculoCompra.estadoPago(sinCargas: false, totalMp: 100, pagado: 0), EstadoPago.porPagar);
      expect(CalculoCompra.estadoPago(sinCargas: false, totalMp: 100, pagado: 100), EstadoPago.pagado);
      expect(CalculoCompra.estadoPago(sinCargas: false, totalMp: 100, pagado: 120), EstadoPago.pagadoDeMas);
    });

    test('reglas de carga, gasto y pago', () {
      expect(ReglasCompra.carga(camion('c')..kg = 0), 'Ingrese los kg cargados');
      expect(ReglasCompra.carga(camion('c')..destarePct = 120), contains('destare'));
      const otros = CatalogoItem(id: 't', codigo: 'OTROS', nombre: 'OTROS GASTOS', requiereDescripcion: true);
      final g = GastoVinculado(id: 'g', tipoGastoId: 't', fecha: DateTime(2025), monto: 70);
      expect(ReglasCompra.gasto(g, otros), contains('Describa'));
      expect(ReglasCompra.gasto(g..descripcion = 'Viáticos', otros), isNull);
      expect(ReglasCompra.pago(Pago(id: 'p', fecha: DateTime(2025), condicionPagoId: 'c', monto: 0)), 'Ingrese el monto');
    });
  });
}
