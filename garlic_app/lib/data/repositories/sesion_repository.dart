import 'package:flutter/foundation.dart';

import '../../domain/models/sesion.dart';
import '../../utils/result.dart';
import '../services/api/api_client.dart';
import '../services/local/kv_store.dart';

/// Sesión del usuario (login con DNI + contraseña).
///
/// - Guarda los tokens en el dispositivo: con una sesión guardada la app abre y trabaja **sin señal**.
/// - Renueva el access token cuando el servidor responde 401 (un solo refresh a la vez).
/// - Si el servidor rechaza la renovación (sesión vencida, cerrada o usuario desactivado) la sesión queda
///   [expirada]: se pide volver a entrar y lo pendiente se envía después. Los datos locales no se tocan.
class SesionRepository extends ChangeNotifier {
  SesionRepository({required KvStore kv, required ApiClient api}) : _kv = kv, _api = api {
    _api.tokenActual = () => (_pendiente ?? _sesion)?.accessToken;
    _api.renovarSesion = renovar;
  }

  static const _clave = 'sesion';
  static const _claveDni = 'sesion.ultimoDni';

  final KvStore _kv;
  final ApiClient _api;

  Sesion? _sesion;

  /// Login correcto aún sin activar: la pantalla de acceso descarga los catálogos con este token y recién
  /// entonces la activa (así el router no cambia de pantalla a mitad de la descarga).
  Sesion? _pendiente;
  bool _expirada = false;
  String? _ultimoDni;
  Future<bool>? _renovando;

  Sesion? get sesion => _sesion;
  UsuarioSesion? get usuario => _sesion?.usuario;

  /// Hay sesión vigente (o al menos no rechazada por el servidor: sin señal se sigue trabajando).
  bool get autenticado => _sesion != null && !_expirada;

  /// El servidor rechazó la sesión guardada: hay que volver a entrar.
  bool get expirada => _expirada;

  bool get debeCambiarClave => autenticado && _sesion!.usuario.debeCambiarClave;

  /// DNI del último usuario que entró en este dispositivo (para no volver a escribirlo).
  String? get ultimoDni => _ultimoDni;

  Future<void> cargar() async {
    final json = KvStore.mapa(await _kv.leer(_clave));
    _sesion = json == null ? null : Sesion.fromJson(json);
    _ultimoDni = (await _kv.leer(_claveDni)) as String?;
    _expirada = false;
    notifyListeners();
  }

  /// Valida DNI y clave. La sesión queda pendiente hasta [activar].
  Future<Result<Sesion>> login({required String dni, required String clave}) async {
    final r = await _api.postPublico(
      '/api/v1/auth/login',
      body: {'dni': dni.trim(), 'clave': clave, 'dispositivo': kIsWeb ? 'web' : defaultTargetPlatform.name},
    );
    switch (r) {
      case Ok(:final value):
        final sesion = _leer(value);
        if (sesion == null) {
          return const Result.error(AppFailure(FailureKind.desconocido, 'Respuesta inesperada del servidor'));
        }
        _pendiente = sesion;
        return Result.ok(sesion);
      case Error(:final failure):
        return Result.error(failure);
    }
  }

  /// Activa la sesión del último login (la guarda en el dispositivo y avisa al router).
  Future<void> activar() async {
    final s = _pendiente;
    if (s == null) return;
    _pendiente = null;
    await _guardar(s);
    _ultimoDni = s.usuario.dni;
    await _kv.escribir(_claveDni, _ultimoDni);
    notifyListeners();
  }

  /// Descarta un login que no llegó a activarse (falló la descarga inicial).
  void descartarPendiente() => _pendiente = null;

  /// Canjea el refresh token. Si ya hay una renovación en curso, espera esa (no se rota dos veces).
  Future<bool> renovar() => _renovando ??= _renovar().whenComplete(() => _renovando = null);

  Future<bool> _renovar() async {
    final actual = _sesion;
    if (actual == null || _expirada) return false;
    final r = await _api.postPublico('/api/v1/auth/refresh', body: {'refreshToken': actual.refreshToken});
    switch (r) {
      case Ok(:final value):
        final nueva = _leer(value);
        if (nueva == null) return false;
        await _guardar(nueva);
        notifyListeners();
        return true;
      case Error(failure: AppFailure(kind: FailureKind.sinSesion)):
        _expirada = true;
        notifyListeners();
        return false;
      case Error():
        return false; // sin señal: la sesión sigue, se reintenta más tarde
    }
  }

  Future<Result<void>> cambiarClave({required String actual, required String nueva}) async {
    final r = await _api.put('/api/v1/auth/clave', body: {'actual': actual, 'nueva': nueva});
    switch (r) {
      case Ok():
        final s = _sesion;
        if (s != null) {
          await _guardar(s.copyWith(usuario: s.usuario.copyWith(debeCambiarClave: false)));
          notifyListeners();
        }
        return const Result.ok(null);
      case Error(:final failure):
        return Result.error(failure);
    }
  }

  /// Cierra la sesión de este dispositivo. Los datos locales y lo pendiente se conservan.
  Future<void> cerrar() async {
    final s = _sesion;
    _sesion = null;
    _expirada = false;
    await _kv.borrar(_clave);
    notifyListeners();
    if (s != null) {
      // avisar al servidor es opcional (sin señal, la sesión vence sola)
      await _api.postPublico('/api/v1/auth/logout', body: {'refreshToken': s.refreshToken});
    }
  }

  Future<void> _guardar(Sesion s) async {
    _sesion = s;
    _expirada = false;
    await _kv.escribir(_clave, s.toJson());
  }

  static Sesion? _leer(Object? value) {
    final j = KvStore.mapa(value);
    if (j == null || j['accessToken'] == null || j['usuario'] == null || j['empresa'] == null) return null;
    return Sesion.fromJson(j);
  }
}
