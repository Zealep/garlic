import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/lote.dart';
import '../../domain/models/sync.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/app_database.dart';
import '../services/local/kv_store.dart';
import 'catalogos_repository.dart';
import 'sync_repository.dart';

/// Lotes (punto 1). Fuente de verdad local; el servidor se consulta para refrescar y
/// las altas se encolan para sincronizar.
class LotesRepository {
  LotesRepository({
    required AppDatabase db,
    required ApiClient api,
    required SyncRepository sync,
    required CatalogosRepository catalogos,
  }) : _db = db,
       _api = api,
       _sync = sync,
       _catalogos = catalogos;

  final AppDatabase _db;
  final ApiClient _api;
  final SyncRepository _sync;
  final CatalogosRepository _catalogos;

  Stream<List<Lote>> observar() =>
      (_db.select(_db.lotesLocal)
        ..orderBy([(t) => OrderingTerm.desc(t.actualizado)])).watch().map((filas) => filas.map(_aLote).toList());

  Stream<Lote?> observarUno(String id) =>
      (_db.select(_db.lotesLocal)
        ..where((t) => t.id.equals(id))).watchSingleOrNull().map((f) => f == null ? null : _aLote(f));

  Future<Lote?> obtener(String id) async {
    final f = await (_db.select(_db.lotesLocal)..where((t) => t.id.equals(id))).getSingleOrNull();
    return f == null ? null : _aLote(f);
  }

  /// Descarga los lotes del servidor. No pisa los que tienen cambios locales sin sincronizar.
  Future<Result<void>> refrescar() async {
    final r = await _api.get('/api/v1/lotes', query: {'size': 200, 'sort': 'createdAt,desc'});
    if (r case Error(:final failure)) return Result.error(failure);
    final lotes = KvStore.lista(KvStore.mapa((r as Ok<Object?>).value)?['content']);
    final locales = {for (final f in await _db.select(_db.lotesLocal).get()) f.id: f};
    await _db.batch((b) {
      for (final json in lotes) {
        final local = locales[json['id']];
        if (local != null && local.syncState != SyncState.sincronizado.name) continue;
        b.insert(_db.lotesLocal, _fila(json, SyncState.sincronizado), mode: InsertMode.insertOrReplace);
      }
    });
    return const Result.ok(null);
  }

  /// Registra un lote en el teléfono y lo encola. Valida la zona repetida también sin conexión.
  Future<Result<Lote>> crear(NuevoLote nuevo) async {
    final zona = _normalizarZona(nuevo.zona);
    final repetido = (await _db.select(_db.lotesLocal).get())
        .map(_aLote)
        .where((l) => l.activo && l.campania.id == nuevo.campaniaId && _normalizarZona(l.zona) == zona);
    if (repetido.isNotEmpty) {
      return Result.error(
        AppFailure(
          FailureKind.conflicto,
          'Ya existe el lote ${repetido.first.codigo} en la zona $zona para esta campaña',
          fieldErrors: {'zona': 'Zona ya registrada (${repetido.first.codigo})'},
        ),
      );
    }

    final json = _jsonLocal(nuevo);
    await _db.into(_db.lotesLocal).insert(_fila(json, SyncState.pendiente));
    await _sync.encolar(
      tipo: TipoOperacion.loteUpsert,
      entidadId: nuevo.id,
      descripcion: 'Lote ${json['codigo']} · zona ${nuevo.zona}',
      payload: nuevo.toRequestJson(),
    );
    return Result.ok(Lote.fromJson(json, syncState: SyncState.pendiente));
  }

  /// Arma la vista del lote con los nombres de la caché de catálogos (mientras no llega la respuesta del API).
  Map<String, Object?> _jsonLocal(NuevoLote n) {
    final campania = _catalogos.buscar(_catalogos.campanias, n.campaniaId);
    final variedad = _catalogos.buscar(_catalogos.variedades, n.variedadId);
    final tipoCompra = _catalogos.buscar(_catalogos.tiposCompra, n.tipoCompraId);
    final localidad = _catalogos.buscar(_catalogos.localidades, n.localidadId);
    final agricultor = _catalogos.agricultores.where((a) => a.id == n.agricultorId).firstOrNull;
    final proveedor = _catalogos.proveedores.where((a) => a.id == n.proveedorId).firstOrNull;
    final req = n.toRequestJson();
    return {
      ...req,
      'codigo': n.codigo.trim().toUpperCase(),
      'estado': 'ACTIVO',
      'campania': {'id': n.campaniaId, 'codigo': campania?.codigo, 'nombre': null},
      'cultivoId': _catalogos.formulario?.cultivoId ?? '',
      'variedad': {'id': n.variedadId, 'codigo': variedad?.codigo, 'nombre': variedad?.nombre},
      'agricultor': {
        'id': n.agricultorId,
        'nombres': agricultor?.nombres ?? '—',
        'numeroDocumento': agricultor?.documento,
      },
      'proveedor':
          proveedor == null
              ? null
              : {'id': proveedor.id, 'nombres': proveedor.nombres, 'numeroDocumento': proveedor.documento},
      'titularLiquidacion':
          n.titular == null
              ? null
              : {
                'id': '',
                'nombres': n.titular!.nombres,
                'tipoDocumento': 'DNI',
                'numeroDocumento': n.titular!.numeroDocumento,
              },
      'localidad': {'id': n.localidadId, 'codigo': null, 'nombre': localidad?.nombre},
      'tipoCompra': {'id': n.tipoCompraId, 'codigo': tipoCompra?.codigo, 'nombre': tipoCompra?.nombre},
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static String _normalizarZona(String z) => z.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  static LotesLocalCompanion _fila(Map<String, Object?> json, SyncState estado) => LotesLocalCompanion.insert(
    id: json['id']! as String,
    json: jsonEncode(json),
    codigo: json['codigo']! as String,
    zona: json['zona']! as String,
    agricultor: ((json['agricultor'] as Map?)?['nombres'] ?? '') as String,
    estado: (json['estado'] ?? 'ACTIVO') as String,
    syncState: estado.name,
    actualizado: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
  );

  static Lote _aLote(LotesLocalData f) => Lote.fromJson(
    (jsonDecode(f.json) as Map).cast<String, Object?>(),
    syncState: SyncState.parse(f.syncState),
    syncError: f.syncError,
  );
}
