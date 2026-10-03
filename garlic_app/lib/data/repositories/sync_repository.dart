import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/sync.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/conectividad_service.dart';
import '../services/local/app_database.dart';
import '../services/local/kv_store.dart';

/// Motor de sincronización offline-first (patrón outbox).
///
/// - Los repositorios guardan primero en la base local y encolan una operación.
/// - Este motor envía la cola en orden cuando hay red (al encolar, al recuperar conexión,
///   periódicamente y a pedido del usuario).
/// - Los IDs los genera el teléfono y el backend crea de forma idempotente: reintentar nunca duplica.
/// - Errores de red: se reintenta después (backoff). Errores de negocio (409/422): la operación
///   queda bloqueada con el mensaje del servidor hasta que el usuario corrija o reintente.
class SyncRepository extends ChangeNotifier {
  SyncRepository({
    required AppDatabase db,
    required ApiClient api,
    required ConectividadService conectividad,
    required KvStore kv,
  }) : _db = db,
       _api = api,
       _conectividad = conectividad,
       _kv = kv;

  final AppDatabase _db;
  final ApiClient _api;
  final ConectividadService _conectividad;
  final KvStore _kv;

  SyncResumen _resumen = const SyncResumen();
  StreamSubscription<bool>? _redSub;
  Timer? _timer;
  Timer? _debounce;
  int _fallosSeguidos = 0;

  SyncResumen get resumen => _resumen;

  Future<void> iniciar() async {
    final ultima = await _kv.leer('sync.ultima');
    _resumen = _resumen.copyWith(
      online: await _conectividad.hayRed(),
      ultimaSincronizacion: ultima is String ? DateTime.tryParse(ultima) : null,
    );
    await _recontar();
    _redSub = _conectividad.cambios.listen((online) {
      _resumen = _resumen.copyWith(online: online);
      notifyListeners();
      if (online) programar();
    });
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_resumen.pendientes > 0) unawaited(sincronizar());
    });
    programar();
  }

  @override
  void dispose() {
    _redSub?.cancel();
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  /// Encola una operación. Si [reemplazar] es true y ya existe una del mismo tipo para la entidad
  /// sin enviar, se reemplaza su contenido (p. ej. varios guardados del mismo borrador = 1 envío).
  Future<void> encolar({
    required TipoOperacion tipo,
    required String entidadId,
    required String descripcion,
    required Map<String, Object?> payload,
    bool reemplazar = false,
  }) async {
    if (reemplazar) {
      final actualizadas = await (_db.update(_db.outbox)
        ..where((t) => t.tipo.equals(tipo.name) & t.entidadId.equals(entidadId))).write(
        OutboxCompanion(
          payload: Value(jsonEncode(payload)),
          descripcion: Value(descripcion),
          bloqueada: const Value(false),
          ultimoError: const Value(null),
        ),
      );
      if (actualizadas > 0) {
        await _recontar();
        programar();
        return;
      }
    }
    await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            tipo: tipo.name,
            entidadId: entidadId,
            descripcion: descripcion,
            payload: jsonEncode(payload),
            creado: DateTime.now(),
          ),
        );
    await _recontar();
    programar();
  }

  /// Quita de la cola las operaciones de una entidad (p. ej. foto eliminada antes de subirse).
  Future<void> descartarDeEntidad(String entidadId) async {
    await (_db.delete(_db.outbox)..where((t) => t.entidadId.equals(entidadId))).go();
    await _recontar();
  }

  /// Sincroniza pronto (agrupa varias llamadas seguidas).
  void programar({Duration espera = const Duration(milliseconds: 600)}) {
    _debounce?.cancel();
    _debounce = Timer(espera, () => unawaited(sincronizar()));
  }

  Stream<List<OperacionPendiente>> observarCola() =>
      (_db.select(_db.outbox)..orderBy([(t) => OrderingTerm.asc(t.seq)])).watch().map(
        (filas) =>
            filas
                .map(
                  (f) => OperacionPendiente(
                    seq: f.seq,
                    tipo: TipoOperacion.parse(f.tipo),
                    entidadId: f.entidadId,
                    descripcion: f.descripcion,
                    intentos: f.intentos,
                    creado: f.creado,
                    ultimoError: f.bloqueada ? f.ultimoError : null,
                  ),
                )
                .toList(),
      );

  /// Desbloquea las operaciones con error y vuelve a intentar.
  Future<void> reintentarTodo() async {
    await _db.update(_db.outbox).write(const OutboxCompanion(bloqueada: Value(false)));
    _fallosSeguidos = 0;
    await sincronizar();
  }

  Future<Result<void>> sincronizar() async {
    if (_resumen.sincronizando) return const Result.ok(null);
    _resumen = _resumen.copyWith(sincronizando: true);
    notifyListeners();
    AppFailure? falloRed;
    try {
      final cola =
          await (_db.select(_db.outbox)
                ..where((t) => t.bloqueada.equals(false))
                ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
              .get();
      for (final op in cola) {
        final r = await _procesar(op);
        switch (r) {
          case Ok():
            await (_db.delete(_db.outbox)..where((t) => t.seq.equals(op.seq))).go();
            await _actualizarEstadoEntidad(TipoOperacion.parse(op.tipo), op.entidadId);
          case Error(:final failure) when failure.esReintentable:
            await (_db.update(_db.outbox)..where(
              (t) => t.seq.equals(op.seq),
            )).write(OutboxCompanion(intentos: Value(op.intentos + 1), ultimoError: Value(failure.message)));
            falloRed = failure;
          case Error(:final failure):
            await (_db.update(_db.outbox)..where((t) => t.seq.equals(op.seq))).write(
              OutboxCompanion(
                intentos: Value(op.intentos + 1),
                ultimoError: Value(failure.message),
                bloqueada: const Value(true),
              ),
            );
            await _marcarEntidad(TipoOperacion.parse(op.tipo), op.entidadId, SyncState.error, failure.message);
        }
        if (falloRed != null) break; // sin servidor: no tiene sentido seguir
      }
      if (falloRed == null) {
        _fallosSeguidos = 0;
        final ahora = DateTime.now();
        await _kv.escribir('sync.ultima', ahora.toIso8601String());
        _resumen = _resumen.copyWith(ultimaSincronizacion: ahora, limpiarError: true);
      } else {
        _fallosSeguidos++;
        _resumen = _resumen.copyWith(ultimoError: falloRed.message);
        // backoff exponencial con tope de 5 minutos
        programar(espera: Duration(seconds: min(300, 5 * pow(2, _fallosSeguidos).toInt())));
      }
    } finally {
      _resumen = _resumen.copyWith(sincronizando: false);
      await _recontar();
    }
    return falloRed == null ? const Result.ok(null) : Result.error(falloRed);
  }

  // ------------------------------------------------------------------ envío por tipo

  Future<Result<void>> _procesar(OutboxData op) async {
    final payload = (jsonDecode(op.payload) as Map).cast<String, Object?>();
    return switch (TipoOperacion.parse(op.tipo)) {
      TipoOperacion.loteUpsert => _upsertLote(op.entidadId, payload),
      TipoOperacion.evaluacionUpsert => _upsertEvaluacion(op.entidadId, payload),
      TipoOperacion.evaluacionCerrar => _resultado(await _api.post('/api/v1/evaluaciones/${op.entidadId}/cerrar')),
      TipoOperacion.evidenciaSubir => _subirEvidencia(op.entidadId, payload),
      TipoOperacion.recursoGuardar => _resultado(
        await _api.put(payload['ruta']! as String, body: (payload['body']! as Map).cast<String, Object?>()),
      ),
      TipoOperacion.recursoEliminar => _eliminarRecurso(payload['ruta']! as String),
      TipoOperacion.comprobanteSubir => _subirComprobante(op.entidadId),
    };
  }

  /// Actualiza; si el servidor no lo conoce aún, lo crea con el id del teléfono.
  Future<Result<void>> _upsertLote(String id, Map<String, Object?> request) async {
    var r = await _api.put('/api/v1/lotes/$id', body: request);
    if (r case Error(failure: AppFailure(kind: FailureKind.noEncontrado))) {
      r = await _api.post('/api/v1/lotes', body: request);
    }
    if (r case Ok(:final value)) {
      final json = KvStore.mapa(value)!;
      await (_db.update(_db.lotesLocal)..where((t) => t.id.equals(id))).write(
        LotesLocalCompanion(
          json: Value(jsonEncode(json)),
          codigo: Value(json['codigo']! as String),
          zona: Value(json['zona']! as String),
        ),
      );
    }
    return _resultado(r);
  }

  Future<Result<void>> _upsertEvaluacion(String id, Map<String, Object?> payload) async {
    final request = (payload['request']! as Map).cast<String, Object?>();
    var r = await _api.put('/api/v1/evaluaciones/$id', body: request);
    if (r case Error(failure: AppFailure(kind: FailureKind.noEncontrado))) {
      r = await _api.post('/api/v1/lotes/${payload['loteId']}/evaluaciones', body: request);
    }
    return _resultado(r);
  }

  Future<Result<void>> _subirEvidencia(String id, Map<String, Object?> payload) async {
    final foto = await (_db.select(_db.evidenciasLocal)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (foto == null) return const Result.ok(null); // se eliminó localmente
    final extension = foto.mime.split('/').last.replaceAll('jpeg', 'jpg');
    return _resultado(
      await _api.subirArchivo(
        '/api/v1/evaluaciones/${foto.evaluacionId}/evidencias',
        bytes: foto.bytes,
        nombreArchivo: 'evidencia-$id.$extension',
        mime: foto.mime,
        campos: {'id': id, 'muestraNumero': foto.muestraNumero, 'factor': foto.factor},
      ),
    );
  }

  /// Si el servidor ya no lo tiene (nunca llegó o ya se borró), el objetivo está cumplido.
  Future<Result<void>> _eliminarRecurso(String ruta) async {
    final r = await _api.delete(ruta);
    if (r case Error(failure: AppFailure(kind: FailureKind.noEncontrado))) return const Result.ok(null);
    return _resultado(r);
  }

  Future<Result<void>> _subirComprobante(String id) async {
    final foto = await (_db.select(_db.comprobantesLocal)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (foto == null) return const Result.ok(null); // se eliminó localmente
    final extension = foto.mime.split('/').last.replaceAll('jpeg', 'jpg');
    return _resultado(
      await _api.subirArchivo(
        '/api/v1/lotes/${foto.loteId}/comprobantes',
        bytes: foto.bytes,
        nombreArchivo: 'comprobante-$id.$extension',
        mime: foto.mime,
        campos: {'id': id, 'entidad': foto.entidad, 'entidadId': foto.entidadId},
      ),
    );
  }

  static Result<void> _resultado(Result<Object?> r) => switch (r) {
    Ok() => const Result.ok(null),
    Error(:final failure) => Result.error(failure),
  };

  // ------------------------------------------------------------------ estado por registro

  Future<void> _actualizarEstadoEntidad(TipoOperacion tipo, String entidadId) async {
    final quedan = await (_db.select(_db.outbox)..where((t) => t.entidadId.equals(entidadId))).get();
    final estado =
        quedan.isEmpty
            ? SyncState.sincronizado
            : (quedan.any((o) => o.bloqueada) ? SyncState.error : SyncState.pendiente);
    await _marcarEntidad(tipo, entidadId, estado, estado == SyncState.error ? quedan.first.ultimoError : null);
  }

  Future<void> _marcarEntidad(TipoOperacion tipo, String id, SyncState estado, String? error) async {
    switch (tipo) {
      case TipoOperacion.loteUpsert:
        await (_db.update(_db.lotesLocal)..where(
          (t) => t.id.equals(id),
        )).write(LotesLocalCompanion(syncState: Value(estado.name), syncError: Value(error)));
      case TipoOperacion.evaluacionUpsert || TipoOperacion.evaluacionCerrar:
        await (_db.update(_db.evaluacionesLocal)..where(
          (t) => t.id.equals(id),
        )).write(EvaluacionesLocalCompanion(syncState: Value(estado.name), syncError: Value(error)));
      case TipoOperacion.evidenciaSubir:
        await (_db.update(_db.evidenciasLocal)
          ..where((t) => t.id.equals(id))).write(EvidenciasLocalCompanion(syncState: Value(estado.name)));
      case TipoOperacion.recursoGuardar || TipoOperacion.recursoEliminar:
        await (_db.update(_db.movimientosCompraLocal)..where(
          (t) => t.id.equals(id),
        )).write(MovimientosCompraLocalCompanion(syncState: Value(estado.name), syncError: Value(error)));
      case TipoOperacion.comprobanteSubir:
        await (_db.update(_db.comprobantesLocal)
          ..where((t) => t.id.equals(id))).write(ComprobantesLocalCompanion(syncState: Value(estado.name)));
    }
  }

  Future<void> _recontar() async {
    final cola = await _db.select(_db.outbox).get();
    _resumen = _resumen.copyWith(
      pendientes: cola.where((o) => !o.bloqueada).length,
      errores: cola.where((o) => o.bloqueada).length,
    );
    notifyListeners();
  }
}
