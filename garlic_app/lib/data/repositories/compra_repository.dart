import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/compra.dart';
import '../../domain/models/foto.dart';
import '../../domain/models/sync.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/app_database.dart';
import '../services/local/kv_store.dart';
import 'sync_repository.dart';

/// Punto 3 (compra del lote): fijación de precio, cargas, gastos vinculados, pagos y sus fotos.
///
/// Offline-first: cada registro se guarda en el equipo y se encola un PUT idempotente con el UUID del
/// teléfono (el backend crea o actualiza). Al eliminar se encola un DELETE (404 cuenta como hecho).
class CompraRepository {
  CompraRepository({required AppDatabase db, required ApiClient api, required SyncRepository sync, required KvStore kv})
    : _db = db,
      _api = api,
      _sync = sync,
      _kv = kv;

  static const _uuid = Uuid();
  static const _clavePrecios = 'compra.ultimosPreciosBase';

  final AppDatabase _db;
  final ApiClient _api;
  final SyncRepository _sync;
  final KvStore _kv;

  String nuevoId() => _uuid.v4();

  static String idFijacion(String loteId) => 'fijacion:$loteId';

  // ------------------------------------------------------------------ lectura

  Stream<CompraLote> observar(String loteId) =>
      (_db.select(_db.movimientosCompraLocal)..where((t) => t.loteId.equals(loteId))).watch().map((filas) {
        FijacionPrecio? fijacion;
        final cargas = <Carga>[];
        final gastos = <GastoVinculado>[];
        final pagos = <Pago>[];
        for (final f in filas) {
          final json = (jsonDecode(f.json) as Map).cast<String, Object?>();
          final estado = SyncState.parse(f.syncState);
          switch (f.tipo) {
            case 'fijacion':
              fijacion = FijacionPrecio.fromJson(json, syncState: estado, syncError: f.syncError);
            case 'carga':
              cargas.add(Carga.fromJson(json, syncState: estado, syncError: f.syncError));
            case 'gasto':
              gastos.add(GastoVinculado.fromJson(json, syncState: estado, syncError: f.syncError));
            case 'pago':
              pagos.add(Pago.fromJson(json, syncState: estado, syncError: f.syncError));
          }
        }
        cargas.sort((a, b) => a.fecha.compareTo(b.fecha));
        gastos.sort((a, b) => a.fecha.compareTo(b.fecha));
        pagos.sort((a, b) => a.fecha.compareTo(b.fecha));
        return CompraLote(loteId: loteId, fijacion: fijacion, cargas: cargas, gastos: gastos, pagos: pagos);
      });

  /// Trae la compra del servidor sin pisar los registros con cambios locales por enviar.
  Future<Result<void>> refrescar(String loteId) async {
    final r = await _api.get('/api/v1/lotes/$loteId/compra');
    if (r case Error(:final failure)) return Result.error(failure);
    final json = KvStore.mapa((r as Ok<Object?>).value)!;
    final enCola = {for (final o in await _db.select(_db.outbox).get()) o.entidadId};
    final remotos = <String, (String, Map<String, Object?>)>{};
    final fijacion = KvStore.mapa(json['fijacion']);
    if (fijacion != null) remotos[idFijacion(loteId)] = ('fijacion', fijacion);
    for (final (tipo, clave) in [('carga', 'cargas'), ('gasto', 'gastos'), ('pago', 'pagos')]) {
      for (final item in KvStore.lista(json[clave])) {
        remotos[item['id']! as String] = (tipo, item);
      }
    }
    final locales = await (_db.select(_db.movimientosCompraLocal)..where((t) => t.loteId.equals(loteId))).get();
    await _db.batch((b) {
      // borrados en el servidor (y sin cambios locales)
      for (final l in locales) {
        if (!remotos.containsKey(l.id) && !enCola.contains(l.id)) {
          b.deleteWhere(_db.movimientosCompraLocal, (t) => t.id.equals(l.id));
        }
      }
      for (final e in remotos.entries) {
        if (enCola.contains(e.key)) continue;
        b.insert(
          _db.movimientosCompraLocal,
          MovimientosCompraLocalCompanion.insert(
            id: e.key,
            loteId: loteId,
            tipo: e.value.$1,
            json: jsonEncode(e.value.$2),
            syncState: SyncState.sincronizado.name,
            actualizado: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    return const Result.ok(null);
  }

  // ------------------------------------------------------------------ escritura

  Future<void> guardarFijacion(String loteId, String loteCodigo, FijacionPrecio f) async {
    await _guardar(
      id: idFijacion(loteId),
      loteId: loteId,
      tipo: 'fijacion',
      json: f.toRequestJson(),
      ruta: '/api/v1/lotes/$loteId/fijacion-precio',
      body: f.toRequestJson(),
      descripcion: 'Precio ${f.pactado ? 'pactado' : 'en cálculo'} · $loteCodigo',
    );
    await _kv.escribir(_clavePrecios, f.preciosBase);
  }

  /// Últimos precios base usados (para prellenar la fijación del siguiente lote).
  Future<Map<String, double>> ultimosPreciosBase() async {
    final m = KvStore.mapa(await _kv.leer(_clavePrecios)) ?? const {};
    return {for (final e in m.entries) e.key: (e.value as num).toDouble()};
  }

  Future<void> guardarCarga(String loteId, String loteCodigo, Carga c) => _guardar(
    id: c.id,
    loteId: loteId,
    tipo: 'carga',
    json: c.toJson(),
    ruta: '/api/v1/lotes/$loteId/cargas/${c.id}',
    body: c.toRequestJson(),
    descripcion: 'Carga ${c.kg.toStringAsFixed(0)} kg · $loteCodigo',
  );

  Future<void> guardarGasto(String loteId, String loteCodigo, GastoVinculado g) => _guardar(
    id: g.id,
    loteId: loteId,
    tipo: 'gasto',
    json: g.toJson(),
    ruta: '/api/v1/lotes/$loteId/gastos/${g.id}',
    body: g.toRequestJson(),
    descripcion: 'Gasto S/ ${g.monto.toStringAsFixed(2)} · $loteCodigo',
  );

  Future<void> guardarPago(String loteId, String loteCodigo, Pago p) => _guardar(
    id: p.id,
    loteId: loteId,
    tipo: 'pago',
    json: p.toJson(),
    ruta: '/api/v1/lotes/$loteId/pagos/${p.id}',
    body: p.toRequestJson(),
    descripcion: 'Pago S/ ${p.monto.toStringAsFixed(2)} · $loteCodigo',
  );

  /// Elimina en el equipo (con sus fotos) y encola el borrado en el servidor.
  Future<void> eliminar({required String loteId, required String id, required String tipo, required String descripcion}) async {
    await _sync.descartarDeEntidad(id);
    final fotos = await (_db.select(_db.comprobantesLocal)..where((t) => t.entidadId.equals(id))).get();
    for (final f in fotos) {
      await _sync.descartarDeEntidad(f.id);
    }
    await (_db.delete(_db.comprobantesLocal)..where((t) => t.entidadId.equals(id))).go();
    await (_db.delete(_db.movimientosCompraLocal)..where((t) => t.id.equals(id))).go();
    final ruta = switch (tipo) {
      'carga' => 'cargas',
      'gasto' => 'gastos',
      _ => 'pagos',
    };
    await _sync.encolar(
      tipo: TipoOperacion.recursoEliminar,
      entidadId: id,
      descripcion: descripcion,
      payload: {'ruta': '/api/v1/lotes/$loteId/$ruta/$id'},
    );
  }

  Future<void> _guardar({
    required String id,
    required String loteId,
    required String tipo,
    required Map<String, Object?> json,
    required String ruta,
    required Map<String, Object?> body,
    required String descripcion,
  }) async {
    await _db
        .into(_db.movimientosCompraLocal)
        .insertOnConflictUpdate(
          MovimientosCompraLocalCompanion.insert(
            id: id,
            loteId: loteId,
            tipo: tipo,
            json: jsonEncode(json),
            syncState: SyncState.pendiente.name,
            actualizado: DateTime.now(),
          ),
        );
    await _sync.encolar(
      tipo: TipoOperacion.recursoGuardar,
      entidadId: id,
      descripcion: descripcion,
      payload: {'ruta': ruta, 'body': body},
      reemplazar: true,
    );
  }

  // ------------------------------------------------------------------ comprobantes (fotos)

  Stream<List<ComprobanteLocal>> observarComprobantes(String loteId) => (_db.select(_db.comprobantesLocal)
        ..where((t) => t.loteId.equals(loteId))
        ..orderBy([(t) => OrderingTerm.asc(t.creado)]))
      .watch()
      .map(
        (filas) =>
            filas
                .map(
                  (f) => ComprobanteLocal(
                    id: f.id,
                    entidadId: f.entidadId,
                    bytes: f.bytes,
                    mime: f.mime,
                    creado: f.creado,
                    syncState: SyncState.parse(f.syncState),
                  ),
                )
                .toList(),
      );

  /// La foto se sube después del registro al que pertenece (la cola respeta el orden).
  Future<void> agregarComprobante({
    required String loteId,
    required EntidadComprobante entidad,
    required String entidadId,
    required Uint8List bytes,
    required String mime,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.comprobantesLocal)
        .insert(
          ComprobantesLocalCompanion.insert(
            id: id,
            loteId: loteId,
            entidad: entidad.api,
            entidadId: entidadId,
            bytes: bytes,
            mime: mime,
            syncState: SyncState.pendiente.name,
            creado: DateTime.now(),
          ),
        );
    await _sync.encolar(
      tipo: TipoOperacion.comprobanteSubir,
      entidadId: id,
      descripcion: entidad.etiqueta,
      payload: const {},
    );
  }

  /// Solo fotos aún no subidas.
  Future<void> eliminarComprobante(String id) async {
    await _sync.descartarDeEntidad(id);
    await (_db.delete(_db.comprobantesLocal)..where((t) => t.id.equals(id))).go();
  }
}

/// Foto de respaldo guardada en el equipo.
class ComprobanteLocal implements FotoLocal {
  const ComprobanteLocal({
    required this.id,
    required this.entidadId,
    required this.bytes,
    required this.mime,
    required this.creado,
    this.syncState = SyncState.pendiente,
  });

  @override
  final String id;
  final String entidadId;
  @override
  final Uint8List bytes;
  final String mime;
  final DateTime creado;
  @override
  final SyncState syncState;
}
