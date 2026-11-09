import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/data/repositories/catalogos_repository.dart';
import 'package:garlic_app/data/repositories/config_repository.dart';
import 'package:garlic_app/data/repositories/evaluaciones_repository.dart';
import 'package:garlic_app/data/repositories/lotes_repository.dart';
import 'package:garlic_app/data/repositories/sesion_repository.dart';
import 'package:garlic_app/data/repositories/sync_repository.dart';
import 'package:garlic_app/ui/core/theme/tema.dart';
import 'package:garlic_app/ui/features/acceso/view_models/acceso_view_model.dart';
import 'package:garlic_app/ui/features/acceso/views/acceso_screen.dart';
import 'package:mocktail/mocktail.dart';

class _Sesion extends Mock implements SesionRepository {}

class _Config extends Mock implements ConfigRepository {}

class _Catalogos extends Mock implements CatalogosRepository {}

class _Lotes extends Mock implements LotesRepository {}

class _Evaluaciones extends Mock implements EvaluacionesRepository {}

class _Sync extends Mock implements SyncRepository {}

void main() {
  late _Sesion sesion;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final config = _Config();
    when(() => config.config).thenReturn(null);
    final vm = AccesoViewModel(
      sesion: sesion,
      config: config,
      catalogos: _Catalogos(),
      lotes: _Lotes(),
      evaluaciones: _Evaluaciones(),
      sync: _Sync(),
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(MaterialApp(theme: TemaGarlic.claro(), home: AccesoScreen(viewModel: vm)));
    await tester.pumpAndSettle();
  }

  setUp(() {
    sesion = _Sesion();
    when(() => sesion.ultimoDni).thenReturn('72790829');
    when(() => sesion.expirada).thenReturn(false);
  });

  testWidgets('en el celular: logo, DNI recordado, contraseña y validación del DNI', (tester) async {
    await abrir(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('72790829'), findsOneWidget, reason: 'recuerda el último DNI del dispositivo');
    expect(
      find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/marca/logo-blanco.png',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'DNI'), '123');
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.text('El DNI tiene 8 dígitos'), findsOneWidget);
    expect(find.text('Ingrese su contraseña'), findsOneWidget);
    verifyNever(() => sesion.login(dni: any(named: 'dni'), clave: any(named: 'clave')));
  });

  testWidgets('sesión vencida: avisa que lo registrado sin conexión se conserva', (tester) async {
    when(() => sesion.expirada).thenReturn(true);
    await abrir(tester);

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
