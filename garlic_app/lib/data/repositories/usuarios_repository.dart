import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/kv_store.dart';

/// Usuario del sistema tal como lo ve el administrador.
class UsuarioItem {
  const UsuarioItem({
    required this.id,
    required this.nombres,
    required this.dni,
    this.email,
    required this.admin,
    required this.activo,
    required this.tieneClave,
    this.ultimoAcceso,
  });

  factory UsuarioItem.fromJson(Map<String, Object?> j) => UsuarioItem(
    id: j['id']! as String,
    nombres: j['nombres']! as String,
    dni: (j['dni'] as String?) ?? '',
    email: j['email'] as String?,
    admin: j['rol'] == 'ADMIN',
    activo: (j['activo'] as bool?) ?? true,
    tieneClave: (j['tieneClave'] as bool?) ?? false,
    ultimoAcceso: DateTime.tryParse((j['ultimoAcceso'] as String?) ?? '')?.toLocal(),
  );

  final String id;
  final String nombres;
  final String dni;
  final String? email;
  final bool admin;
  final bool activo;
  final bool tieneClave;
  final DateTime? ultimoAcceso;
}

/// Gestión de usuarios (solo administrador, requiere conexión: no pasa por la cola offline).
class UsuariosRepository {
  UsuariosRepository({required ApiClient api}) : _api = api;

  static const _base = '/api/v1/usuarios';
  final ApiClient _api;

  Future<Result<List<UsuarioItem>>> listar() async {
    final r = await _api.get(_base, query: {'size': 200, 'sort': 'nombres'});
    return switch (r) {
      Ok(:final value) => Result.ok(
        KvStore.lista(KvStore.mapa(value)?['content']).map(UsuarioItem.fromJson).toList(),
      ),
      Error(:final failure) => Result.error(failure),
    };
  }

  /// Alta con contraseña temporal (el usuario la cambia al entrar).
  Future<Result<UsuarioItem>> crear({
    required String nombres,
    required String dni,
    String? email,
    required bool admin,
    required String claveTemporal,
  }) => _uno(
    _api.post(
      _base,
      body: {
        'nombres': nombres.trim(),
        'dni': dni.trim(),
        'email': (email ?? '').trim().isEmpty ? null : email!.trim(),
        'rol': admin ? 'ADMIN' : 'EVALUADOR',
        'clave': claveTemporal,
      },
    ),
  );

  Future<Result<UsuarioItem>> actualizar(UsuarioItem u, {required String nombres, String? email, required bool admin}) =>
      _uno(
        _api.put(
          '$_base/${u.id}',
          body: {
            'nombres': nombres.trim(),
            'dni': u.dni,
            'email': (email ?? '').trim().isEmpty ? null : email!.trim(),
            'rol': admin ? 'ADMIN' : 'EVALUADOR',
          },
        ),
      );

  /// Contraseña temporal (olvido o primer ingreso): cierra sus sesiones abiertas.
  Future<Result<UsuarioItem>> asignarClave(String id, String claveTemporal) =>
      _uno(_api.put('$_base/$id/clave', body: {'clave': claveTemporal}));

  Future<Result<void>> desactivar(String id) async {
    final r = await _api.delete('$_base/$id');
    return switch (r) {
      Ok() => const Result.ok(null),
      Error(:final failure) => Result.error(failure),
    };
  }

  Future<Result<UsuarioItem>> activar(String id) => _uno(_api.patch('$_base/$id/activar'));

  static Future<Result<UsuarioItem>> _uno(Future<Result<Object?>> peticion) async {
    final r = await peticion;
    return switch (r) {
      Ok(:final value) => switch (KvStore.mapa(value)) {
        final j? => Result.ok(UsuarioItem.fromJson(j)),
        null => const Result.error(AppFailure(FailureKind.desconocido, 'Respuesta inesperada del servidor')),
      },
      Error(:final failure) => Result.error(failure),
    };
  }
}
