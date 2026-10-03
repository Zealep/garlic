import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/data/repositories/compra_repository.dart';
import 'package:garlic_app/data/repositories/sync_repository.dart';
import 'package:garlic_app/data/services/api/api_client.dart';
import 'package:garlic_app/data/services/conectividad_service.dart';
import 'package:garlic_app/data/services/local/app_database.dart';
import 'package:garlic_app/data/services/local/kv_store.dart';
import 'package:garlic_app/domain/models/compra.dart';
import 'package:garlic_app/domain/models/sync.dart';
import 'package:garlic_app/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/open.dart';

class _ApiFalsa extends Mock implements ApiClient {}

class _RedFalsa extends Mock implements ConectividadService {}

const _noEncontrado = AppFailure(FailureKind.noEncontrado, 'no existe', statusCode: 404);
const _sinRed = AppFailure(FailureKind.sinConexion, 'No se pudo conectar con el servidor');

void main() {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  }

  late AppDatabase db;
  late _ApiFalsa api;
  late SyncRepository sync;
  late CompraRepository compra;

  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _ApiFalsa();
    final red = _RedFalsa();
    when(() => red.hayRed()).thenAnswer((_) async => true);
    when(() => red.cambios).thenAnswer((_) => const Stream.empty());
    final kv = KvStore(db);
    sync = SyncRepository(db: db, api: api, conectividad: red, kv: kv);
    compra = CompraRepository(db: db, api: api, sync: sync, kv: kv);
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  Pago pago(String id, double monto) => Pago(id: id, fecha: DateTime(2025, 10, 21), condicionPagoId: 'cta', monto: monto);

  test('pago sin conexión: queda pendiente y luego se envía con PUT idempotente', () async {
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.error(_sinRed));
    await compra.guardarPago('l-1', 'LOTE 004', pago('p-1', 500));
    await sync.sincronizar();

    var actual = await compra.observar('l-1').first;
    expect(actual.pagos.single.syncState, SyncState.pendiente);
    expect(actual.balance.totalPagado, 500);

    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.ok(<String, Object?>{}));
    await sync.sincronizar();

    verify(() => api.put('/api/v1/lotes/l-1/pagos/p-1', body: any(named: 'body'))).called(2);
    actual = await compra.observar('l-1').first;
    expect(actual.pagos.single.syncState, SyncState.sincronizado);
    expect(await db.select(db.outbox).get(), isEmpty);
  });

  test('eliminar: se quita del equipo y el DELETE con 404 cuenta como hecho', () async {
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.ok(<String, Object?>{}));
    when(() => api.delete(any())).thenAnswer((_) async => const Result.error(_noEncontrado));
    await compra.guardarPago('l-1', 'LOTE 004', pago('p-2', 100));
    await compra.eliminar(loteId: 'l-1', id: 'p-2', tipo: 'pago', descripcion: 'Eliminar pago');

    // el PUT pendiente se descartó: solo queda el DELETE
    final cola = await db.select(db.outbox).get();
    expect(cola.single.tipo, TipoOperacion.recursoEliminar.name);

    final r = await sync.sincronizar();
    expect(r, isA<Ok<void>>());
    verifyNever(() => api.put(any(), body: any(named: 'body')));
    verify(() => api.delete('/api/v1/lotes/l-1/pagos/p-2')).called(1);
    expect((await compra.observar('l-1').first).pagos, isEmpty);
  });

  test('refrescar trae lo del servidor sin pisar cambios locales pendientes', () async {
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.error(_sinRed));
    await compra.guardarPago('l-1', 'LOTE 004', pago('local', 300));
    when(() => api.get('/api/v1/lotes/l-1/compra')).thenAnswer(
      (_) async => const Result.ok(<String, Object?>{
        'loteId': 'l-1',
        'fijacion': {
          'evaluacionId': 'ev-1',
          'precios': [
            {'claseCalidadId': 'c-primera', 'precioBase': 3.4},
          ],
          'gastoLlenado': 0.3,
          'precioPactado': 2.8,
        },
        'cargas': [
          {'id': 'c-1', 'fecha': '2025-10-20', 'kg': 15000, 'precioKg': 2.8, 'destarePct': 1, 'cantidadEmpaques': 375},
        ],
        'gastos': <Object?>[],
        'pagos': [
          {'id': 'local', 'fecha': '2025-10-21', 'condicionPagoId': 'cta', 'monto': 999},
          {'id': 'remoto', 'fecha': '2025-10-22', 'condicionPagoId': 'cta', 'monto': 1000},
        ],
      }),
    );

    await compra.refrescar('l-1');
    final c = await compra.observar('l-1').first;
    expect(c.fijacion!.precioPactado, 2.8);
    expect(c.cargas.single.calculo.total, 41580);
    expect(c.pagos.map((p) => (p.id, p.monto)), [('local', 300.0), ('remoto', 1000.0)]);
    expect(c.balance.saldo, 41580 - 1300);
  });
}
