import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/data/repositories/catalogos_repository.dart';
import 'package:garlic_app/data/repositories/compra_repository.dart';
import 'package:garlic_app/data/repositories/evaluaciones_repository.dart';
import 'package:garlic_app/data/repositories/lotes_repository.dart';
import 'package:garlic_app/domain/models/compra.dart';
import 'package:garlic_app/domain/models/lote.dart';
import 'package:garlic_app/ui/core/theme/tema.dart';
import 'package:garlic_app/ui/features/comparacion/view_models/comparacion_view_model.dart';
import 'package:garlic_app/ui/features/comparacion/views/comparacion_screen.dart';
import 'package:garlic_app/utils/result.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../domain/comparacion_evaluaciones_test.dart' show evaluacion, formulario, primera, segunda;

class _Evaluaciones extends Mock implements EvaluacionesRepository {}

class _Lotes extends Mock implements LotesRepository {}

class _Catalogos extends Mock implements CatalogosRepository {}

class _Compra extends Mock implements CompraRepository {}

Lote _lote(String id, String codigo) => Lote.fromJson({
  'id': id,
  'codigo': codigo,
  'estado': 'ACTIVO',
  'campania': {'id': 'c1', 'nombre': '2025'},
  'cultivoId': 'ajo',
  'variedad': {'id': 'v1', 'nombre': 'NAPURI'},
  'agricultor': {'id': 'p1', 'nombres': 'JUAN PEREZ'},
  'localidad': {'id': 'loc', 'nombre': 'AREQUIPA'},
  'zona': 'ZONA $codigo',
  'tipoCompra': {'id': 't1', 'nombre': 'CAMPO'},
});

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('compara dos evaluaciones: resalta el ganador y calcula el valor por kg', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final evaluaciones = _Evaluaciones();
    final lotes = _Lotes();
    final catalogos = _Catalogos();
    final compra = _Compra();
    final a = evaluacion('a', [80, 85, 75]);
    final b = evaluacion('b', [70, 70, 70]);
    when(() => catalogos.formulario).thenReturn(formulario);
    when(() => evaluaciones.observar()).thenAnswer((_) => Stream.value(const []));
    when(() => evaluaciones.cargar('a')).thenAnswer((_) async => Result.ok(a));
    when(() => evaluaciones.cargar('b')).thenAnswer((_) async => Result.ok(b));
    when(() => lotes.obtener('l-a')).thenAnswer((_) async => _lote('l-a', 'LOTE 001'));
    when(() => lotes.obtener('l-b')).thenAnswer((_) async => _lote('l-b', 'LOTE 002'));
    when(
      () => compra.observar(any()),
    ).thenAnswer((i) => Stream.value(CompraLote(loteId: i.positionalArguments[0] as String)));
    when(() => compra.ultimosPreciosBase()).thenAnswer((_) async => {primera: 3.4, segunda: 1.4});

    final vm = ComparacionViewModel(
      idA: 'a',
      idB: 'b',
      evaluaciones: evaluaciones,
      lotes: lotes,
      catalogos: catalogos,
      compra: compra,
    );
    await tester.pumpWidget(MaterialApp(theme: TemaGarlic.claro(), home: ComparacionScreen(viewModel: vm)));
    await tester.pumpAndSettle();

    expect(find.text('LOTE 001'), findsOneWidget);
    expect(find.text('LOTE 002'), findsOneWidget);
    expect(find.text('Con estos precios, A vale S/ 0,20 más por kg.'), findsOneWidget);
    expect(find.textContaining('A es mejor en 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    vm.intercambiar();
    await tester.pump();
    expect(find.text('Con estos precios, B vale S/ 0,20 más por kg.'), findsOneWidget);
  });
}
