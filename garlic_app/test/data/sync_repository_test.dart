import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/data/repositories/sync_repository.dart';
import 'package:garlic_app/data/services/api/api_client.dart';
import 'package:garlic_app/data/services/conectividad_service.dart';
import 'package:garlic_app/data/services/local/app_database.dart';
import 'package:garlic_app/data/services/local/kv_store.dart';
import 'package:garlic_app/domain/models/sync.dart';
import 'package:garlic_app/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/open.dart';

class _ApiFalsa extends Mock implements ApiClient {}

class _RedFalsa extends Mock implements ConectividadService {}

const _noEncontrado = AppFailure(FailureKind.noEncontrado, 'no existe', statusCode: 404);
const _sinRed = AppFailure(FailureKind.sinConexion, 'No se pudo conectar con el servidor');
const _zonaRepetida = AppFailure(
  FailureKind.conflicto,
  'Ya existe el lote LOTE 004 en la zona B3 P52',
  statusCode: 409,
);

Map<String, Object?> _loteJson(String id) => {
  'id': id,
  'codigo': 'LOTE 008',
  'zona': 'B7 P21',
  'estado': 'ACTIVO',
  'agricultor': {'nombres': 'WERNER'},
};

void main() {
  // En Windows los tests usan el SQLite del sistema (sin plugins de Flutter).
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  }

  late AppDatabase db;
  late _ApiFalsa api;
  late SyncRepository sync;

  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = _ApiFalsa();
    final red = _RedFalsa();
    when(() => red.hayRed()).thenAnswer((_) async => true);
    when(() => red.cambios).thenAnswer((_) => const Stream.empty());
    sync = SyncRepository(db: db, api: api, conectividad: red, kv: KvStore(db));
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  Future<void> insertarLotePendiente(String id) => db
      .into(db.lotesLocal)
      .insert(
        LotesLocalCompanion.insert(
          id: id,
          json: '{}',
          codigo: 'LOTE 008',
          zona: 'B7 P21',
          agricultor: 'WERNER',
          estado: 'ACTIVO',
          syncState: SyncState.pendiente.name,
          actualizado: DateTime.now(),
        ),
      );

  Future<void> encolarLote(String id) => sync.encolar(
    tipo: TipoOperacion.loteUpsert,
    entidadId: id,
    descripcion: 'Lote LOTE 008',
    payload: {'id': id, 'codigo': 'LOTE 008'},
  );

  Future<LotesLocalData> lote(String id) => (db.select(db.lotesLocal)..where((t) => t.id.equals(id))).getSingle();

  test('lote nuevo: PUT 404 -> POST con el id del teléfono, se quita de la cola y queda sincronizado', () async {
    await insertarLotePendiente('l-1');
    when(
      () => api.put('/api/v1/lotes/l-1', body: any(named: 'body')),
    ).thenAnswer((_) async => const Result.error(_noEncontrado));
    when(
      () => api.post('/api/v1/lotes', body: any(named: 'body')),
    ).thenAnswer((_) async => Result.ok(_loteJson('l-1')));

    await encolarLote('l-1');
    final r = await sync.sincronizar();

    expect(r, isA<Ok<void>>());
    verify(() => api.post('/api/v1/lotes', body: {'id': 'l-1', 'codigo': 'LOTE 008'})).called(1);
    expect(await db.select(db.outbox).get(), isEmpty);
    expect((await lote('l-1')).syncState, SyncState.sincronizado.name);
    expect(sync.resumen.pendientes, 0);
  });

  test('sin conexión: la operación queda en cola con el intento registrado', () async {
    await insertarLotePendiente('l-2');
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.error(_sinRed));

    await encolarLote('l-2');
    final r = await sync.sincronizar();

    expect(r, isA<Error<void>>());
    final cola = await db.select(db.outbox).get();
    expect(cola.single.intentos, 1);
    expect(cola.single.bloqueada, isFalse);
    expect(sync.resumen.pendientes, 1);
    expect((await lote('l-2')).syncState, SyncState.pendiente.name);
  });

  test('rechazo del servidor (409): se bloquea, el lote queda con error y se puede reintentar', () async {
    await insertarLotePendiente('l-3');
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.error(_zonaRepetida));

    await encolarLote('l-3');
    await sync.sincronizar();

    expect(sync.resumen.errores, 1);
    final l = await lote('l-3');
    expect(l.syncState, SyncState.error.name);
    expect(l.syncError, contains('zona B3 P52'));

    // el usuario corrige en el servidor y reintenta
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => Result.ok(_loteJson('l-3')));
    await sync.reintentarTodo();
    expect(sync.resumen.errores, 0);
    expect((await lote('l-3')).syncState, SyncState.sincronizado.name);
  });

  test('guardados sucesivos del mismo borrador se envían una sola vez (coalescencia)', () async {
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((_) async => const Result.error(_sinRed));
    for (var i = 1; i <= 3; i++) {
      await sync.encolar(
        tipo: TipoOperacion.evaluacionUpsert,
        entidadId: 'ev-1',
        descripcion: 'Evaluación',
        payload: {
          'loteId': 'l-1',
          'request': {'version': i},
        },
        reemplazar: true,
      );
    }
    final cola = await db.select(db.outbox).get();
    expect(cola, hasLength(1));
    expect(cola.single.payload, contains('"version":3'));
  });

  test('las operaciones se envían en el orden en que se hicieron', () async {
    final orden = <String>[];
    when(() => api.put(any(), body: any(named: 'body'))).thenAnswer((inv) async {
      orden.add(inv.positionalArguments.first as String);
      return const Result.ok(<String, Object?>{});
    });
    when(() => api.post(any(), body: any(named: 'body'))).thenAnswer((inv) async {
      orden.add(inv.positionalArguments.first as String);
      return const Result.ok(<String, Object?>{});
    });

    await sync.encolar(
      tipo: TipoOperacion.evaluacionUpsert,
      entidadId: 'ev-9',
      descripcion: 'Evaluación',
      payload: {'loteId': 'l-1', 'request': <String, Object?>{}},
    );
    await sync.encolar(
      tipo: TipoOperacion.evaluacionCerrar,
      entidadId: 'ev-9',
      descripcion: 'Cierre',
      payload: const {},
    );
    await sync.sincronizar();

    expect(orden, ['/api/v1/evaluaciones/ev-9', '/api/v1/evaluaciones/ev-9/cerrar']);
  });
}
