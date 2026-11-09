import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/data/repositories/catalogos_repository.dart';
import 'package:garlic_app/data/repositories/config_repository.dart';
import 'package:garlic_app/data/repositories/evaluaciones_repository.dart';
import 'package:garlic_app/data/repositories/lotes_repository.dart';
import 'package:garlic_app/domain/models/catalogo.dart';
import 'package:garlic_app/domain/models/evaluacion.dart';
import 'package:garlic_app/domain/models/lote.dart';
import 'package:garlic_app/domain/use_cases/reglas_evaluacion.dart';
import 'package:garlic_app/ui/core/theme/tema.dart';
import 'package:garlic_app/ui/features/evaluacion/view_models/evaluacion_view_model.dart';
import 'package:garlic_app/ui/features/evaluacion/views/evaluacion_screen.dart';
import 'package:garlic_app/utils/result.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../domain/evaluacion_borrador_test.dart' show cerosa, formulario, loteModelo;

class _Lotes extends Mock implements LotesRepository {}

class _Evaluaciones extends Mock implements EvaluacionesRepository {}

class _Catalogos extends Mock implements CatalogosRepository {}

class _Config extends Mock implements ConfigRepository {}

class _Borrador extends Fake implements EvaluacionBorrador {}

class _Lote extends Fake implements Lote {}

void main() {
  setUpAll(() {
    registerFallbackValue(_Borrador());
    registerFallbackValue(_Lote());
    return initializeDateFormatting('es');
  });

  testWidgets('cada muestra tiene sus sensoriales, sanidad y parálisis con %; al quitar la 1 se renumera', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 5200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final lotes = _Lotes();
    final evaluaciones = _Evaluaciones();
    final catalogos = _Catalogos();
    final config = _Config();
    final lote = Lote.fromJson({
      'id': 'lote-1',
      'codigo': 'LOTE 009',
      'estado': 'ACTIVO',
      'campania': {'id': 'c', 'codigo': '2025'},
      'cultivoId': 'ajo',
      'variedad': {'id': 'v', 'nombre': 'CHINO MORADO'},
      'agricultor': {'id': 'a', 'nombres': 'SONIA'},
      'zona': 'B3 P53',
      'latitud': -16.3,
      'longitud': -72.1,
      'tipoCompra': {'id': 't', 'nombre': 'PRIMERA'},
    });
    when(() => lotes.obtener('lote-1')).thenAnswer((_) async => lote);
    when(() => catalogos.formulario).thenReturn(formulario);
    when(() => catalogos.evaluadores).thenReturn(const [PersonaItem(id: 'u-1', nombres: 'Evaluador')]);
    when(() => config.config).thenReturn(null);
    when(() => evaluaciones.cargar('ev-1')).thenAnswer((_) async => Result.ok(loteModelo()));
    when(() => evaluaciones.observarEvidencias('ev-1')).thenAnswer((_) => Stream.value(const []));
    when(
      () => evaluaciones.guardar(any(), any(), evaluadorNombre: any(named: 'evaluadorNombre')),
    ).thenAnswer((_) async {});

    final vm = EvaluacionViewModel(
      loteId: 'lote-1',
      evaluacionId: 'ev-1',
      lotes: lotes,
      evaluaciones: evaluaciones,
      catalogos: catalogos,
      config: config,
    );
    await tester.pumpWidget(MaterialApp(theme: TemaGarlic.claro(), home: EvaluacionScreen(viewModel: vm)));
    await tester.pumpAndSettle();
    expect(lote.ubicacionTexto, startsWith('GPS'));

    vm.irA(PasoEvaluacion.muestras);
    vm.seleccionarMuestra(1); // la muestra 2 tiene parálisis 10 de 20
    await tester.pumpAndSettle();

    expect(find.text('Sensoriales'), findsOneWidget);
    expect(find.text('Sanidad'), findsOneWidget);
    expect(find.text('Copiar de M1'), findsOneWidget);
    expect(find.text('Frutos total'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    vm.setFrutosDano(cerosa, afectados: 5);
    await tester.pumpAndSettle();
    expect(find.text('25%'), findsOneWidget);

    await vm.quitarMuestra(vm.borrador!.muestras.first);
    await tester.pumpAndSettle();
    expect(vm.borrador!.muestras.map((m) => m.numero), [1, 2]);
    expect(find.text('Muestra 3'), findsNothing);

    // el resumen destaca la parálisis
    vm.irA(PasoEvaluacion.resumen);
    await tester.pumpAndSettle();
    expect(find.text('Parálisis · % de daño'), findsOneWidget);
    expect(find.text('M1: 25% (5/20)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    vm.dispose();
  });

  testWidgets('evaluación cerrada: se puede cambiar de muestra tocando su tarjeta (solo lectura)', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final lotes = _Lotes();
    final evaluaciones = _Evaluaciones();
    final catalogos = _Catalogos();
    final config = _Config();
    final lote = Lote.fromJson({
      'id': 'lote-1',
      'codigo': 'LOTE 009',
      'estado': 'ACTIVO',
      'campania': {'id': 'c', 'codigo': '2025'},
      'cultivoId': 'ajo',
      'variedad': {'id': 'v', 'nombre': 'CHINO MORADO'},
      'agricultor': {'id': 'a', 'nombres': 'SONIA'},
      'zona': 'B3 P53',
      'latitud': -16.3,
      'longitud': -72.1,
      'tipoCompra': {'id': 't', 'nombre': 'PRIMERA'},
    });
    when(() => lotes.obtener('lote-1')).thenAnswer((_) async => lote);
    when(() => catalogos.formulario).thenReturn(formulario);
    when(() => catalogos.evaluadores).thenReturn(const [PersonaItem(id: 'u-1', nombres: 'Evaluador')]);
    when(() => config.config).thenReturn(null);
    when(
      () => evaluaciones.cargar('ev-1'),
    ).thenAnswer((_) async => Result.ok(loteModelo()..estado = EstadoEvaluacion.cerrada));
    when(() => evaluaciones.observarEvidencias('ev-1')).thenAnswer((_) => Stream.value(const []));

    final vm = EvaluacionViewModel(
      loteId: 'lote-1',
      evaluacionId: 'ev-1',
      lotes: lotes,
      evaluaciones: evaluaciones,
      catalogos: catalogos,
      config: config,
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(MaterialApp(theme: TemaGarlic.claro(), home: EvaluacionScreen(viewModel: vm)));
    await tester.pumpAndSettle();
    expect(vm.editable, isFalse);

    vm.irA(PasoEvaluacion.muestras);
    await tester.pumpAndSettle();
    expect(find.text('Fotos de la muestra 1'), findsOneWidget);

    await tester.tap(find.text('Muestra 2'));
    await tester.pumpAndSettle();

    expect(vm.muestraIndice, 1);
    expect(find.text('Fotos de la muestra 2'), findsOneWidget);
    expect(find.textContaining('Quitar muestra'), findsNothing, reason: 'solo lectura');
    expect(tester.takeException(), isNull);
  });
}
