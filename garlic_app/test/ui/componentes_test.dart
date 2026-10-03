import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/compra.dart';
import 'package:garlic_app/domain/models/evaluacion.dart';
import 'package:garlic_app/domain/models/sync.dart';
import 'package:garlic_app/ui/core/layout/breakpoints.dart';
import 'package:garlic_app/ui/core/theme/tema.dart';
import 'package:garlic_app/ui/core/widgets/componentes.dart';
import 'package:garlic_app/ui/core/widgets/evaluacion_tile.dart';
import 'package:garlic_app/ui/features/compra/views/widgets/balance_compra.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _app(Widget child) => MaterialApp(theme: TemaGarlic.claro(), home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('Anchos de ventana (flutter-build-responsive-layout)', () {
    test('se decide por el ancho disponible', () {
      expect(AnchoVentana.de(390), AnchoVentana.compacto);
      expect(AnchoVentana.de(820), AnchoVentana.medio);
      expect(AnchoVentana.de(1440), AnchoVentana.expandido);
    });
  });

  testWidgets('EvaluacionTile muestra lote, estado, calidad y estado de sincronización', (tester) async {
    var tocado = false;
    await tester.pumpWidget(
      _app(
        EvaluacionTile(
          evaluacion: EvaluacionResumen(
            id: 'e1',
            loteId: 'l1',
            loteCodigo: 'LOTE 004',
            zona: 'B3 P52',
            fecha: DateTime(2025, 10, 10),
            estado: EstadoEvaluacion.cerrada,
            nroMuestras: 3,
            evaluador: 'Evaluador Demo',
            promedioPrimera: 80,
            syncState: SyncState.pendiente,
          ),
          onTap: () => tocado = true,
        ),
      ),
    );

    expect(find.text('LOTE 004 · B3 P52'), findsOneWidget);
    expect(find.text('Cerrada'), findsOneWidget);
    expect(find.text('Primera 80%'), findsOneWidget);
    expect(find.byTooltip('Pendiente'), findsOneWidget);

    await tester.tap(find.byType(EvaluacionTile));
    expect(tocado, isTrue);
  });

  testWidgets('Tarjeta de compra del lote: precio pactado, kg netos, saldo y estado de pago', (tester) async {
    var tocado = false;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 420,
          child: ResumenCompraTarjeta(
            compra: CompraLote(
              loteId: 'l1',
              fijacion: FijacionPrecio(evaluacionId: 'e1', precioPactado: 2.8),
              cargas: [Carga(id: 'c1', fecha: DateTime(2025, 10, 20), kg: 15000, precioKg: 2.8)],
              pagos: [Pago(id: 'p1', fecha: DateTime(2025, 10, 21), condicionPagoId: 'cta', monto: 10000)],
            ),
            onTap: () => tocado = true,
          ),
        ),
      ),
    );

    expect(find.text('Pago parcial'), findsOneWidget);
    expect(find.textContaining('2,80'), findsOneWidget);
    expect(find.text('14.850 kg'), findsOneWidget);
    expect(find.text('S/ 31.580,00'), findsOneWidget);

    await tester.tap(find.text('Saldo'));
    expect(tocado, isTrue);
  });

  testWidgets('EstadoSync nunca comunica solo con color: siempre hay texto', (tester) async {
    await tester.pumpWidget(_app(const EstadoSync(estado: SyncState.error)));
    expect(find.text('Con error'), findsOneWidget);
  });

  testWidgets('Los botones principales cumplen el tamaño táctil mínimo (48dp)', (tester) async {
    await tester.pumpWidget(_app(FilledButton(onPressed: () {}, child: const Text('Guardar'))));
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
