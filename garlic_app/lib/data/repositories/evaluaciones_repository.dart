import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/evaluacion.dart';
import '../../domain/models/lote.dart';
import '../../domain/models/sync.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/app_database.dart';
import '../services/local/kv_store.dart';
import 'sync_repository.dart';

/// Evaluaciones de calidad (punto 2) y sus fotos. El borrador vive en el teléfono y se
/// sincroniza completo en cada guardado (el backend reemplaza el contenido del borrador).
class EvaluacionesRepository {
  EvaluacionesRepository({required AppDatabase db, required ApiClient api, required SyncRepository sync})
    : _db = db,
      _api = api,
      _sync = sync;

  static const _uuid = Uuid();

  final AppDatabase _db;
  final ApiClient _api;
  final SyncRepository _sync;

  Stream<List<EvaluacionResumen>> observar({String? loteId}) {
    final q = _db.select(_db.evaluacionesLocal)
      ..orderBy([(t) => OrderingTerm.desc(t.fecha), (t) => OrderingTerm.desc(t.actualizado)]);
    if (loteId != null) q.where((t) => t.loteId.equals(loteId));
    return q.watch().map((filas) => filas.map(_aResumen).toList());
  }

  /// Descarga la bandeja del servidor sin pisar borradores con cambios locales.
  Future<Result<void>> refrescar() async {
    final r = await _api.get('/api/v1/evaluaciones', query: {'size': 200});
    if (r case Error(:final failure)) return Result.error(failure);
    final lista = KvStore.lista(KvStore.mapa((r as Ok<Object?>).value)?['content']);
    final locales = {for (final f in await _db.select(_db.evaluacionesLocal).get()) f.id: f};
    await _db.batch((b) {
      for (final json in lista) {
        final local = locales[json['id']];
        if (local != null && local.syncState != SyncState.sincronizado.name) continue;
        final resumen = EvaluacionResumen.fromJson(json);
        b.insert(
          _db.evaluacionesLocal,
          EvaluacionesLocalCompanion.insert(
            id: resumen.id,
            loteId: resumen.loteId,
            resumenJson: jsonEncode({
              ...json,
              'promedioPrimera': local == null ? null : _resumenDe(local)['promedioPrimera'],
            }),
            borradorJson: Value(local?.borradorJson),
            estado: resumen.estado.api,
            fecha: resumen.fecha,
            syncState: SyncState.sincronizado.name,
            actualizado: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    return const Result.ok(null);
  }

  EvaluacionBorrador nuevo({required String loteId, String? evaluadorId, int muestras = 3}) => EvaluacionBorrador(
    id: _uuid.v4(),
    loteId: loteId,
    evaluadorId: evaluadorId,
    fecha: DateTime.now(),
    muestras: [for (var i = 1; i <= muestras; i++) MuestraBorrador(numero: i)],
  );

  /// Borrador local si existe; si no, el detalle del servidor.
  Future<Result<EvaluacionBorrador>> cargar(String id) async {
    final local = await (_db.select(_db.evaluacionesLocal)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local?.borradorJson != null) {
      return Result.ok(
        EvaluacionBorrador.fromRequestJson(
          (jsonDecode(local!.borradorJson!) as Map).cast<String, Object?>(),
          loteId: local.loteId,
          estado: EstadoEvaluacion.parse(local.estado),
        ),
      );
    }
    final r = await _api.get('/api/v1/evaluaciones/$id');
    return switch (r) {
      Ok(:final value) => Result.ok(EvaluacionBorrador.fromResponseJson(KvStore.mapa(value)!)),
      Error(:final failure) => Result.error(failure),
    };
  }

  /// Guarda en el teléfono y encola el envío (varios guardados seguidos se envían una vez).
  Future<void> guardar(EvaluacionBorrador ev, Lote lote, {required String? evaluadorNombre}) async {
    await _guardarLocal(ev, lote, evaluadorNombre);
    await _sync.encolar(
      tipo: TipoOperacion.evaluacionUpsert,
      entidadId: ev.id,
      descripcion: 'Evaluación ${lote.codigo} · ${ev.muestras.length} muestras',
      payload: {'loteId': lote.id, 'request': ev.toRequestJson()},
      reemplazar: true,
    );
  }

  /// Cierra: guarda el contenido final y encola el cierre (después del último guardado).
  Future<void> cerrar(EvaluacionBorrador ev, Lote lote, {required String? evaluadorNombre}) async {
    await guardar(ev, lote, evaluadorNombre: evaluadorNombre);
    ev.estado = EstadoEvaluacion.cerrada;
    await _guardarLocal(ev, lote, evaluadorNombre);
    await _sync.encolar(
      tipo: TipoOperacion.evaluacionCerrar,
      entidadId: ev.id,
      descripcion: 'Cierre de evaluación ${lote.codigo}',
      payload: const {},
    );
  }

  Future<void> _guardarLocal(EvaluacionBorrador ev, Lote lote, String? evaluadorNombre) async {
    final primera = ev.promediosCalidad().values.firstOrNull;
    final resumen = EvaluacionResumen(
      id: ev.id,
      loteId: lote.id,
      loteCodigo: lote.codigo,
      zona: lote.zona,
      fecha: ev.fecha,
      estado: ev.estado,
      evaluador: evaluadorNombre,
      nroMuestras: ev.muestras.length,
      promedioPrimera: primera,
    );
    await _db
        .into(_db.evaluacionesLocal)
        .insertOnConflictUpdate(
          EvaluacionesLocalCompanion.insert(
            id: ev.id,
            loteId: lote.id,
            resumenJson: jsonEncode(resumen.toJson()),
            borradorJson: Value(jsonEncode({...ev.toRequestJson(), 'estado': ev.estado.api})),
            estado: ev.estado.api,
            fecha: ev.fecha,
            syncState: SyncState.pendiente.name,
            actualizado: DateTime.now(),
          ),
        );
  }

  // ------------------------------------------------------------------ evidencias

  Stream<List<EvidenciaLocal>> observarEvidencias(String evaluacionId) => (_db.select(_db.evidenciasLocal)
        ..where((t) => t.evaluacionId.equals(evaluacionId))
        ..orderBy([(t) => OrderingTerm.asc(t.creado)]))
      .watch()
      .map(
        (filas) =>
            filas
                .map(
                  (f) => EvidenciaLocal(
                    id: f.id,
                    evaluacionId: f.evaluacionId,
                    muestraNumero: f.muestraNumero,
                    factor: f.factor,
                    bytes: f.bytes,
                    mime: f.mime,
                    creado: f.creado,
                    syncState: SyncState.parse(f.syncState),
                  ),
                )
                .toList(),
      );

  Future<void> agregarEvidencia({
    required String evaluacionId,
    required Uint8List bytes,
    required String mime,
    int? muestraNumero,
    String? factor,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.evidenciasLocal)
        .insert(
          EvidenciasLocalCompanion.insert(
            id: id,
            evaluacionId: evaluacionId,
            muestraNumero: Value(muestraNumero),
            factor: Value(factor),
            bytes: bytes,
            mime: mime,
            syncState: SyncState.pendiente.name,
            creado: DateTime.now(),
          ),
        );
    await _sync.encolar(
      tipo: TipoOperacion.evidenciaSubir,
      entidadId: id,
      descripcion: muestraNumero == null ? 'Foto general' : 'Foto muestra $muestraNumero',
      payload: {'evaluacionId': evaluacionId},
    );
  }

  /// Solo fotos aún no subidas (las subidas se eliminan desde el servidor).
  Future<void> eliminarEvidencia(String id) async {
    await _sync.descartarDeEntidad(id);
    await (_db.delete(_db.evidenciasLocal)..where((t) => t.id.equals(id))).go();
  }

  static Map<String, Object?> _resumenDe(EvaluacionesLocalData f) =>
      (jsonDecode(f.resumenJson) as Map).cast<String, Object?>();

  static EvaluacionResumen _aResumen(EvaluacionesLocalData f) =>
      EvaluacionResumen.fromJson(_resumenDe(f), syncState: SyncState.parse(f.syncState), syncError: f.syncError);
}
