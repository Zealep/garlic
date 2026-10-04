import 'package:flutter/foundation.dart';

import '../../domain/models/catalogo.dart';
import '../../domain/models/definicion_catalogo.dart';
import '../../domain/models/formulario.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/kv_store.dart';

/// Catálogos que usa la app en campo. Se descargan con conexión y se leen siempre desde la
/// caché local, así los formularios funcionan sin red.
class CatalogosRepository extends ChangeNotifier {
  CatalogosRepository({required KvStore kv, required ApiClient api}) : _kv = kv, _api = api;

  final KvStore _kv;
  final ApiClient _api;

  FormularioEvaluacion? _formulario;
  List<CatalogoItem> _campanias = const [];
  List<CatalogoItem> _variedades = const [];
  List<CatalogoItem> _tiposCompra = const [];
  List<CatalogoItem> _localidades = const [];
  List<CatalogoItem> _tiposEmpaque = const [];
  List<CatalogoItem> _tiposGasto = const [];
  List<CatalogoItem> _condicionesPago = const [];
  List<PersonaItem> _agricultores = const [];
  List<PersonaItem> _proveedores = const [];
  List<PersonaItem> _evaluadores = const [];
  DateTime? _actualizado;

  FormularioEvaluacion? get formulario => _formulario;
  List<CatalogoItem> get campanias => _campanias;
  List<CatalogoItem> get variedades => _variedades;
  List<CatalogoItem> get tiposCompra => _tiposCompra;
  List<CatalogoItem> get localidades => _localidades;
  List<CatalogoItem> get tiposEmpaque => _tiposEmpaque;
  List<CatalogoItem> get tiposGasto => _tiposGasto;
  List<CatalogoItem> get condicionesPago => _condicionesPago;
  List<PersonaItem> get agricultores => _agricultores;
  List<PersonaItem> get proveedores => _proveedores;
  List<PersonaItem> get evaluadores => _evaluadores;
  DateTime? get actualizado => _actualizado;
  bool get disponibles => _formulario != null;

  /// Lee la caché local (arranque de la app, sin red).
  Future<void> cargar() async {
    final f = KvStore.mapa(await _kv.leer('cat.formulario'));
    _formulario = f == null ? null : FormularioEvaluacion.fromJson(f);
    _campanias = await _items('cat.campanias');
    _variedades = await _items('cat.variedades');
    _tiposCompra = await _items('cat.tiposCompra');
    _localidades = await _items('cat.localidades');
    _tiposEmpaque = await _items('cat.tiposEmpaque');
    _tiposGasto = await _items('cat.tiposGasto');
    _condicionesPago = await _items('cat.condicionesPago');
    _agricultores = await _personas('cat.agricultores');
    _proveedores = await _personas('cat.proveedores');
    _evaluadores = await _personas('cat.evaluadores');
    _actualizado = await _kv.actualizado('cat.formulario');
    notifyListeners();
  }

  /// Descarga todo del servidor y actualiza la caché.
  Future<Result<void>> descargar(String cultivoId) async {
    final formulario = await _api.get('/api/v1/evaluaciones/formulario', query: {'cultivoId': cultivoId});
    if (formulario case Error(:final failure)) return Result.error(failure);
    await _kv.escribir('cat.formulario', (formulario as Ok<Object?>).value);

    const catalogos = {
      'cat.campanias': '/api/v1/catalogos/campanias',
      'cat.variedades': '/api/v1/catalogos/variedades',
      'cat.tiposCompra': '/api/v1/catalogos/tipos-compra',
      'cat.localidades': '/api/v1/catalogos/localidades',
      'cat.tiposEmpaque': '/api/v1/catalogos/tipos-empaque',
      'cat.tiposGasto': '/api/v1/catalogos/tipos-gasto',
      'cat.condicionesPago': '/api/v1/catalogos/condiciones-pago',
    };
    for (final e in catalogos.entries) {
      final r = await _pagina(e.value, {'activo': true, 'cultivoId': cultivoId});
      if (r case Error(:final failure)) return Result.error(failure);
      await _kv.escribir(e.key, (r as Ok<List<Map<String, Object?>>>).value);
    }

    const roles = {'cat.agricultores': '/api/v1/agricultores', 'cat.proveedores': '/api/v1/proveedores'};
    for (final e in roles.entries) {
      final r = await _pagina(e.value, {'activo': true});
      if (r case Error(:final failure)) return Result.error(failure);
      await _kv.escribir(
        e.key,
        (r as Ok<List<Map<String, Object?>>>).value.map((j) => PersonaItem.fromRolJson(j).toJson()).toList(),
      );
    }

    final usuarios = await _pagina('/api/v1/usuarios', {'activo': true});
    if (usuarios case Error(:final failure)) return Result.error(failure);
    await _kv.escribir(
      'cat.evaluadores',
      (usuarios as Ok<List<Map<String, Object?>>>).value.map((j) => PersonaItem.fromUsuarioJson(j).toJson()).toList(),
    );

    await cargar();
    return const Result.ok(null);
  }

  /// Agrega a la caché un agricultor/proveedor creado desde la app.
  Future<void> agregarPersona(String rol, PersonaItem persona) async {
    final clave = rol == 'agricultor' ? 'cat.agricultores' : 'cat.proveedores';
    final actuales = await _personas(clave);
    await _kv.escribir(clave, [...actuales.where((p) => p.id != persona.id), persona].map((p) => p.toJson()).toList());
    await cargar();
  }

  /// Registra un agricultor o proveedor en el servidor (requiere conexión) y lo agrega a la caché.
  /// Si el documento ya existe, el backend reutiliza la persona.
  Future<Result<PersonaItem>> registrarPersona({
    required String rol,
    required String dni,
    required String nombres,
    String? telefono,
  }) async {
    final path = rol == 'agricultor' ? '/api/v1/agricultores' : '/api/v1/proveedores';
    final r = await _api.post(
      path,
      body: {'tipoDocumento': 'DNI', 'numeroDocumento': dni, 'nombres': nombres, 'telefono': telefono},
    );
    switch (r) {
      case Ok(:final value):
        final persona = PersonaItem.fromRolJson(KvStore.mapa(value)!);
        await agregarPersona(rol, persona);
        return Result.ok(persona);
      case Error(:final failure):
        return Result.error(failure);
    }
  }

  // ------------------------------------------------------------------ administración (requiere conexión)

  /// Todos los registros de un catálogo (activos e inactivos) para administrarlo.
  Future<Result<List<Map<String, Object?>>>> listarAdmin(DefinicionCatalogo d, String cultivoId) =>
      _pagina(d.ruta, {if (d.porCultivo) 'cultivoId': cultivoId, 'sort': d.ordenable ? 'orden,asc' : null});

  /// Crea (sin [id]) o reemplaza un registro y actualiza la caché del equipo.
  Future<Result<void>> guardarAdmin(
    DefinicionCatalogo d,
    String cultivoId,
    Map<String, Object?> valores, {
    String? id,
  }) async {
    final body = d.request(valores, cultivoId);
    final r = id == null ? await _api.post(d.ruta, body: body) : await _api.put('${d.ruta}/$id', body: body);
    if (r case Error(:final failure)) return Result.error(failure);
    await descargar(cultivoId);
    return const Result.ok(null);
  }

  /// Baja lógica o reactivación (los registros históricos conservan la referencia).
  Future<Result<void>> cambiarActivoAdmin(
    DefinicionCatalogo d,
    String cultivoId,
    String id, {
    required bool activo,
  }) async {
    final r = activo ? await _api.patch('${d.ruta}/$id/activar') : await _api.delete('${d.ruta}/$id');
    if (r case Error(:final failure)) return Result.error(failure);
    await descargar(cultivoId);
    return const Result.ok(null);
  }

  CatalogoItem? buscar(List<CatalogoItem> lista, String? id) {
    for (final i in lista) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<Result<List<Map<String, Object?>>>> _pagina(String path, Map<String, Object?> filtros) async {
    final r = await _api.get(path, query: {...filtros, 'size': 200});
    return switch (r) {
      Ok(:final value) => Result.ok(KvStore.lista(KvStore.mapa(value)?['content'])),
      Error(:final failure) => Result.error(failure),
    };
  }

  Future<List<CatalogoItem>> _items(String clave) async =>
      KvStore.lista(await _kv.leer(clave)).map(CatalogoItem.fromJson).toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));

  Future<List<PersonaItem>> _personas(String clave) async =>
      KvStore.lista(await _kv.leer(clave)).map(PersonaItem.fromJson).toList()
        ..sort((a, b) => a.nombres.compareTo(b.nombres));
}
