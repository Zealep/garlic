import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../utils/result.dart';

/// Cliente HTTP del backend. Servicio sin estado de negocio: solo transporte.
///
/// - Traduce errores (ProblemDetail RFC 9457) a [AppFailure] sin lanzar excepciones.
/// - Envía el access token de la sesión. Ante un 401 pide renovarlo **una vez** ([renovarSesion], que
///   provee el repositorio de sesión) y reintenta; si no se puede, devuelve [FailureKind.sinSesion].
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;

  /// Access token vigente (null = sin sesión). Lo provee el repositorio de sesión.
  String? Function() tokenActual = _sinToken;

  /// Renueva la sesión con el refresh token; true si hay un access token nuevo.
  Future<bool> Function()? renovarSesion;

  static String? _sinToken() => null;

  String get baseUrl => _dio.options.baseUrl;

  void configurar({required String baseUrl}) {
    _dio.options.baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }

  Future<Result<Object?>> get(String path, {Map<String, Object?>? query}) =>
      _enviar(() => _dio.get<Object?>(path, queryParameters: _sinNulos(query), options: _opciones()));

  Future<Result<Object?>> post(String path, {Object? body}) =>
      _enviar(() => _dio.post<Object?>(path, data: body, options: _opciones()));

  Future<Result<Object?>> put(String path, {Object? body}) =>
      _enviar(() => _dio.put<Object?>(path, data: body, options: _opciones()));

  Future<Result<Object?>> patch(String path, {Object? body}) =>
      _enviar(() => _dio.patch<Object?>(path, data: body, options: _opciones()));

  Future<Result<Object?>> delete(String path) => _enviar(() => _dio.delete<Object?>(path, options: _opciones()));

  /// POST sin token ni renovación (login, refresh, logout).
  Future<Result<Object?>> postPublico(String path, {Object? body}) =>
      _enviar(() => _dio.post<Object?>(path, data: body), renovar: false);

  /// Sube un archivo (multipart) con campos adicionales.
  Future<Result<Object?>> subirArchivo(
    String path, {
    required Uint8List bytes,
    required String nombreArchivo,
    required String mime,
    Map<String, Object?> campos = const {},
  }) {
    final partes = mime.split('/');
    // el formulario se arma en cada intento: un FormData ya enviado no se puede reenviar
    FormData form() => FormData.fromMap({
      ..._sinNulos(campos) ?? {},
      'archivo': MultipartFile.fromBytes(
        bytes,
        filename: nombreArchivo,
        contentType: DioMediaType(partes[0], partes[1]),
      ),
    });
    return _enviar(() => _dio.post<Object?>(path, data: form(), options: _opciones()));
  }

  // El sistema es de una sola empresa: el servidor la conoce, no se envía. Sí se envía el token.
  Options _opciones() {
    final token = tokenActual();
    return Options(headers: {if (token != null) 'Authorization': 'Bearer $token'});
  }

  Future<Result<Object?>> _enviar(Future<Response<Object?>> Function() request, {bool renovar = true}) async {
    try {
      final response = await request();
      return Result.ok(response.data);
    } on DioException catch (e) {
      final fallo = _traducir(e);
      final renovador = renovarSesion;
      if (fallo.kind == FailureKind.sinSesion && renovar && renovador != null) {
        if (await renovador()) return _enviar(request, renovar: false);
        return const Result.error(
          AppFailure(FailureKind.sinSesion, 'Tu sesión expiró. Inicia sesión para continuar.', statusCode: 401),
        );
      }
      return Result.error(fallo);
    }
  }

  static AppFailure _traducir(DioException e) {
    final response = e.response;
    if (response == null) {
      return const AppFailure(FailureKind.sinConexion, 'No se pudo conectar con el servidor');
    }
    final status = response.statusCode ?? 0;
    final data = response.data;
    var mensaje = 'Error del servidor ($status)';
    final campos = <String, String>{};
    if (data is Map) {
      mensaje = (data['detail'] ?? data['title'] ?? mensaje).toString();
      final errores = data['errors'];
      if (errores is List) {
        for (final err in errores.whereType<Map<Object?, Object?>>()) {
          campos['${err['field']}'] = '${err['message']}';
        }
      }
    }
    final kind = switch (status) {
      400 || 422 => FailureKind.validacion,
      401 => FailureKind.sinSesion,
      403 => FailureKind.sinPermiso,
      404 => FailureKind.noEncontrado,
      409 => FailureKind.conflicto,
      >= 500 || 408 || 429 => FailureKind.sinConexion,
      _ => FailureKind.desconocido,
    };
    return AppFailure(kind, mensaje, fieldErrors: campos, statusCode: status);
  }

  static Map<String, Object?>? _sinNulos(Map<String, Object?>? m) =>
      m == null ? null : (Map.of(m)..removeWhere((_, v) => v == null));
}
