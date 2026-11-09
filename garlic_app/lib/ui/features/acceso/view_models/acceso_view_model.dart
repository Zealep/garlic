import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../data/repositories/sesion_repository.dart';
import '../../../../data/repositories/sync_repository.dart';
import '../../../../domain/models/sesion.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Inicio de sesión con DNI + contraseña. Al entrar descarga los catálogos y lotes para trabajar sin señal
/// y envía lo que hubiera quedado pendiente. El evaluador de las evaluaciones es el usuario que entra.
class AccesoViewModel extends ChangeNotifier {
  AccesoViewModel({
    required SesionRepository sesion,
    required ConfigRepository config,
    required CatalogosRepository catalogos,
    required LotesRepository lotes,
    required EvaluacionesRepository evaluaciones,
    required SyncRepository sync,
  }) : _sesion = sesion,
       _config = config,
       _catalogos = catalogos,
       _lotes = lotes,
       _evaluaciones = evaluaciones,
       _sync = sync {
    ingresar = Command(_ingresar);
    apiUrl = config.config?.apiUrl ?? servidorPredeterminado;
  }

  /// `--dart-define=API_URL=https://...` al compilar (APK) fija el servidor.
  static const _apiDefinida = String.fromEnvironment('API_URL');

  /// El servidor no se pregunta: compilado con API_URL o app web publicada (mismo dominio que el API).
  static bool get servidorFijo => _apiDefinida.isNotEmpty || (kIsWeb && kReleaseMode);

  static String get servidorPredeterminado {
    if (_apiDefinida.isNotEmpty) return _apiDefinida;
    if (kIsWeb && kReleaseMode) return Uri.base.origin;
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  final SesionRepository _sesion;
  final ConfigRepository _config;
  final CatalogosRepository _catalogos;
  final LotesRepository _lotes;
  final EvaluacionesRepository _evaluaciones;
  final SyncRepository _sync;

  late final Command<void> ingresar;
  late String apiUrl;
  String dni = '';
  String clave = '';

  String? get ultimoDni => _sesion.ultimoDni;

  /// El servidor rechazó la sesión guardada (venció o la cerraron): se muestra un aviso.
  bool get sesionExpirada => _sesion.expirada;

  Future<Result<void>> _ingresar() async {
    final servidor = servidorFijo ? servidorPredeterminado : apiUrl.trim();
    final empresa = await _config.probarServidor(servidor);
    if (empresa case Error(:final failure)) return Result.error(failure);

    final login = await _sesion.login(dni: dni, clave: clave);
    if (login case Error(:final failure)) return Result.error(failure);
    final sesion = (login as Ok<Sesion>).value;
    final datos = await _config.datosEmpresa(servidor);
    switch (datos) {
      case Error(:final failure):
        _sesion.descartarPendiente();
        return Result.error(failure);
      case Ok(:final value):
        final cultivo = value.cultivos.where((c) => c.codigo == 'AJO').firstOrNull ?? value.cultivos.firstOrNull;
        if (cultivo == null) {
          _sesion.descartarPendiente();
          return const Result.error(AppFailure(FailureKind.validacion, 'La empresa no tiene cultivos configurados'));
        }
        final r = await _catalogos.descargar(cultivo.id);
        if (r case Error(:final failure)) {
          _sesion.descartarPendiente();
          return Result.error(failure);
        }
        await _config.guardar(
          AppConfig(
            apiUrl: servidor,
            empresaId: sesion.empresa.id,
            empresaNombre: sesion.empresa.razonSocial,
            evaluadorId: sesion.usuario.id,
            evaluadorNombre: sesion.usuario.nombres,
            cultivoId: cultivo.id,
          ),
        );
    }
    await _sesion.activar();
    await _lotes.refrescar();
    await _evaluaciones.refrescar();
    // lo que quedó pendiente (p. ej. al vencer la sesión) se envía ahora
    await _sync.sincronizar();
    return const Result.ok(null);
  }
}
