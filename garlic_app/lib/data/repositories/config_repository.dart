import 'package:flutter/foundation.dart';

import '../../domain/models/catalogo.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/kv_store.dart';

/// Configuración del dispositivo: servidor, empresa (tenant) y evaluador.
/// Sin autenticación todavía; cuando exista login, la empresa y el usuario saldrán del token.
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.empresaId,
    required this.empresaNombre,
    required this.evaluadorId,
    required this.evaluadorNombre,
    required this.cultivoId,
  });

  factory AppConfig.fromJson(Map<String, Object?> j) => AppConfig(
    apiUrl: j['apiUrl']! as String,
    empresaId: j['empresaId']! as String,
    empresaNombre: j['empresaNombre']! as String,
    evaluadorId: j['evaluadorId']! as String,
    evaluadorNombre: j['evaluadorNombre']! as String,
    cultivoId: j['cultivoId']! as String,
  );

  final String apiUrl;
  final String empresaId;
  final String empresaNombre;
  final String evaluadorId;
  final String evaluadorNombre;
  final String cultivoId;

  Map<String, Object?> toJson() => {
    'apiUrl': apiUrl,
    'empresaId': empresaId,
    'empresaNombre': empresaNombre,
    'evaluadorId': evaluadorId,
    'evaluadorNombre': evaluadorNombre,
    'cultivoId': cultivoId,
  };
}

class EmpresaOpcion {
  const EmpresaOpcion({required this.id, required this.nombre, required this.ruc});

  final String id;
  final String nombre;
  final String ruc;
}

class ConfigRepository extends ChangeNotifier {
  ConfigRepository({required KvStore kv, required ApiClient api}) : _kv = kv, _api = api;

  static const _clave = 'config';

  final KvStore _kv;
  final ApiClient _api;

  AppConfig? _config;

  AppConfig? get config => _config;
  bool get configurado => _config != null;

  Future<void> cargar() async {
    final json = KvStore.mapa(await _kv.leer(_clave));
    _config = json == null ? null : AppConfig.fromJson(json);
    if (_config != null) {
      _api.configurar(baseUrl: _config!.apiUrl, empresaId: _config!.empresaId);
    }
    notifyListeners();
  }

  Future<void> guardar(AppConfig config) async {
    await _kv.escribir(_clave, config.toJson());
    _config = config;
    _api.configurar(baseUrl: config.apiUrl, empresaId: config.empresaId);
    notifyListeners();
  }

  Future<void> olvidar() async {
    await _kv.borrar(_clave);
    _config = null;
    notifyListeners();
  }

  /// Verifica el servidor y devuelve las empresas disponibles (endpoint de desarrollo).
  Future<Result<List<EmpresaOpcion>>> probarServidor(String apiUrl) async {
    _api.configurar(baseUrl: apiUrl);
    final r = await _api.get('/instalacion/empresas');
    return switch (r) {
      Ok(:final value) => Result.ok(
        KvStore.lista(value)
            .map(
              (e) =>
                  EmpresaOpcion(id: e['id']! as String, nombre: e['razonSocial']! as String, ruc: e['ruc']! as String),
            )
            .toList(),
      ),
      Error(:final failure) => Result.error(failure),
    };
  }

  /// Evaluadores activos y cultivo principal de la empresa elegida.
  Future<Result<({List<PersonaItem> evaluadores, List<CatalogoItem> cultivos})>> datosEmpresa(
    String apiUrl,
    String empresaId,
  ) async {
    _api.configurar(baseUrl: apiUrl, empresaId: empresaId);
    final usuarios = await _api.get('/api/v1/usuarios', query: {'activo': true, 'size': 100});
    final cultivos = await _api.get('/api/v1/catalogos/cultivos');
    if (usuarios case Error(:final failure)) return Result.error(failure);
    if (cultivos case Error(:final failure)) return Result.error(failure);
    final contenido = KvStore.mapa((usuarios as Ok<Object?>).value)?['content'];
    return Result.ok((
      evaluadores: KvStore.lista(contenido).map(PersonaItem.fromUsuarioJson).toList(),
      cultivos: KvStore.lista((cultivos as Ok<Object?>).value).map(CatalogoItem.fromJson).toList(),
    ));
  }
}
