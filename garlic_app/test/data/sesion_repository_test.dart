import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/data/repositories/sesion_repository.dart';
import 'package:garlic_app/data/services/api/api_client.dart';
import 'package:garlic_app/data/services/local/app_database.dart';
import 'package:garlic_app/data/services/local/kv_store.dart';
import 'package:garlic_app/routing/router.dart';
import 'package:garlic_app/routing/rutas.dart';
import 'package:garlic_app/utils/result.dart';
import 'package:sqlite3/open.dart';

/// Servidor falso: responde según la ruta y registra lo que recibe.
class _Servidor implements HttpClientAdapter {
  final pedidos = <RequestOptions>[];
  final rutas = <String, (int, Object?) Function(RequestOptions)>{};
  bool sinRed = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    pedidos.add(o);
    if (sinRed) throw DioException.connectionError(requestOptions: o, reason: 'sin red');
    final h = rutas[o.path];
    final (status, json) = h == null ? (404, {'detail': 'no existe'}) : h(o);
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _sesionJson(String acceso, String refresh, {bool temporal = false}) => {
  'accessToken': acceso,
  'refreshToken': refresh,
  'usuario': {'id': 'u-1', 'nombres': 'Kevin Arely', 'dni': '72790829', 'admin': true, 'debeCambiarClave': temporal},
  'empresa': {'id': 'e-1', 'ruc': '20123456789', 'razonSocial': 'AGROEXPORTADORA GUADALUPE'},
};

void main() {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  }

  late AppDatabase db;
  late _Servidor servidor;
  late ApiClient api;
  late SesionRepository sesion;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    servidor = _Servidor();
    final dio = Dio()..httpClientAdapter = servidor;
    api = ApiClient(dio: dio)..configurar(baseUrl: 'http://servidor');
    sesion = SesionRepository(kv: KvStore(db), api: api);
    await sesion.cargar();
    servidor.rutas['/api/v1/auth/login'] = (o) {
      final b = o.data as Map;
      return b['clave'] == 'clave-correcta'
          ? (200, _sesionJson('acceso-1', 'refresh-1', temporal: true))
          : (401, {'detail': 'DNI o contraseña incorrectos'});
    };
  });

  tearDown(() => db.close());

  Future<void> entrar() async {
    await sesion.login(dni: '72790829', clave: 'clave-correcta');
    await sesion.activar();
  }

  test('login: la sesión queda pendiente hasta activarla y luego se guarda en el dispositivo', () async {
    final r = await sesion.login(dni: '72790829', clave: 'clave-correcta');
    expect(r, isA<Ok<Object?>>());
    expect(sesion.autenticado, isFalse, reason: 'aún descargando catálogos');

    await sesion.activar();
    expect(sesion.autenticado, isTrue);
    expect(sesion.debeCambiarClave, isTrue);
    expect(sesion.ultimoDni, '72790829');

    // otra instancia (app reabierta, sin señal) recupera la sesión
    final reabierta = SesionRepository(kv: KvStore(db), api: api);
    await reabierta.cargar();
    expect(reabierta.autenticado, isTrue);
    expect(reabierta.usuario!.nombres, 'Kevin Arely');
  });

  test('clave incorrecta: devuelve el mensaje del servidor y no hay sesión', () async {
    final r = await sesion.login(dni: '72790829', clave: 'otra');
    final fallo = (r as Error).failure;
    expect(fallo.message, 'DNI o contraseña incorrectos');
    expect(fallo.kind, FailureKind.sinSesion);
    expect(sesion.autenticado, isFalse);
  });

  test('envía el token; ante un 401 renueva una sola vez (aunque fallen dos pedidos) y reintenta', () async {
    await entrar();
    var refrescos = 0;
    servidor.rutas['/api/v1/auth/refresh'] = (o) {
      refrescos++;
      expect((o.data as Map)['refreshToken'], 'refresh-1');
      return (200, _sesionJson('acceso-2', 'refresh-2'));
    };
    servidor.rutas['/api/v1/lotes'] =
        (o) => o.headers['Authorization'] == 'Bearer acceso-2' ? (200, <Object?>[]) : (401, {'detail': 'vencido'});

    final r = await Future.wait([api.get('/api/v1/lotes'), api.get('/api/v1/lotes')]);

    expect(r, everyElement(isA<Ok<Object?>>()));
    expect(refrescos, 1);
    expect(sesion.sesion!.refreshToken, 'refresh-2');
    expect(servidor.pedidos.where((p) => p.path == '/api/v1/auth/refresh').single.headers['Authorization'], isNull);
  });

  test('si el servidor rechaza la renovación la sesión queda expirada (los datos locales no se tocan)', () async {
    await entrar();
    servidor.rutas['/api/v1/auth/refresh'] = (_) => (401, {'detail': 'Su sesion expiro'});
    servidor.rutas['/api/v1/lotes'] = (_) => (401, {'detail': 'vencido'});

    final r = await api.get('/api/v1/lotes');

    final fallo = (r as Error).failure;
    expect(fallo.kind, FailureKind.sinSesion);
    expect(fallo.esReintentable, isTrue, reason: 'el outbox espera, no bloquea');
    expect(sesion.expirada, isTrue);
    expect(sesion.autenticado, isFalse);
    expect(sesion.ultimoDni, '72790829');
  });

  test('sin señal al renovar la sesión NO expira (se sigue trabajando offline)', () async {
    await entrar();
    servidor.rutas['/api/v1/lotes'] = (_) => (401, {'detail': 'vencido'});
    servidor.rutas['/api/v1/auth/refresh'] = (o) => throw DioException.connectionError(requestOptions: o, reason: 'x');

    await api.get('/api/v1/lotes');

    expect(sesion.expirada, isFalse);
    expect(sesion.autenticado, isTrue);
  });

  test('cerrar sesión borra la sesión del dispositivo y avisa al servidor', () async {
    await entrar();
    servidor.rutas['/api/v1/auth/logout'] = (_) => (204, null);

    await sesion.cerrar();

    expect(sesion.autenticado, isFalse);
    expect(servidor.pedidos.last.path, '/api/v1/auth/logout');
    final reabierta = SesionRepository(kv: KvStore(db), api: api);
    await reabierta.cargar();
    expect(reabierta.autenticado, isFalse);
  });

  test('cambiar la clave temporal quita la obligación de cambiarla', () async {
    await entrar();
    servidor.rutas['/api/v1/auth/clave'] = (_) => (200, <String, Object?>{});

    final r = await sesion.cambiarClave(actual: 'clave-correcta', nueva: 'nueva-clave-1');

    expect(r, isA<Ok<void>>());
    expect(sesion.debeCambiarClave, isFalse);
  });

  group('redirección de acceso', () {
    test('sin sesión todo va al login', () {
      expect(redireccionAcceso(ubicacion: Rutas.inicio, autenticado: false, debeCambiarClave: false), Rutas.acceso);
      expect(redireccionAcceso(ubicacion: Rutas.acceso, autenticado: false, debeCambiarClave: false), isNull);
    });

    test('con clave temporal solo se puede cambiarla', () {
      expect(redireccionAcceso(ubicacion: Rutas.lotes, autenticado: true, debeCambiarClave: true), Rutas.clave);
      expect(redireccionAcceso(ubicacion: Rutas.clave, autenticado: true, debeCambiarClave: true), isNull);
    });

    test('con sesión el login lleva a Inicio y el resto pasa', () {
      expect(redireccionAcceso(ubicacion: Rutas.acceso, autenticado: true, debeCambiarClave: false), Rutas.inicio);
      expect(redireccionAcceso(ubicacion: Rutas.lotes, autenticado: true, debeCambiarClave: false), isNull);
      expect(redireccionAcceso(ubicacion: Rutas.clave, autenticado: true, debeCambiarClave: false), isNull);
    });
  });
}
