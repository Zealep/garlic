import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/catalogo.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Primer uso: servidor → evaluador → descarga de catálogos para trabajar sin red.
/// La empresa la define el servidor (el sistema es de una sola empresa).
class SetupViewModel extends ChangeNotifier {
  SetupViewModel({
    required ConfigRepository config,
    required CatalogosRepository catalogos,
    required LotesRepository lotes,
    required EvaluacionesRepository evaluaciones,
  }) : _config = config,
       _catalogos = catalogos,
       _lotes = lotes,
       _evaluaciones = evaluaciones {
    conectar = Command(_conectar);
    finalizar = Command(_finalizar);
    final actual = config.config;
    apiUrl = actual?.apiUrl ?? servidorPredeterminado;
    // Instalación publicada: el servidor es conocido, se conecta solo.
    if (servidorFijo && actual == null) unawaited(conectar.execute());
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

  final ConfigRepository _config;
  final CatalogosRepository _catalogos;
  final LotesRepository _lotes;
  final EvaluacionesRepository _evaluaciones;

  late final Command<void> conectar;
  late final Command<void> finalizar;

  late String apiUrl;
  EmpresaOpcion? empresa;
  List<PersonaItem> evaluadores = const [];
  PersonaItem? evaluador;
  CatalogoItem? cultivo;

  /// 0 = servidor, 1 = evaluador.
  int get paso => empresa == null ? 0 : 1;

  Future<Result<void>> _conectar() async {
    final url = apiUrl.trim();
    final r = await _config.probarServidor(url);
    if (r case Error(:final failure)) return Result.error(failure);
    final datos = await _config.datosEmpresa(url);
    switch (datos) {
      case Ok(:final value):
        empresa = (r as Ok<EmpresaOpcion>).value;
        evaluadores = value.evaluadores;
        evaluador = evaluadores.length == 1 ? evaluadores.first : null;
        cultivo = value.cultivos.where((c) => c.codigo == 'AJO').firstOrNull ?? value.cultivos.firstOrNull;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final failure):
        return Result.error(failure);
    }
  }

  void seleccionarEvaluador(PersonaItem? p) {
    evaluador = p;
    notifyListeners();
  }

  void volver() {
    empresa = null;
    notifyListeners();
  }

  Future<Result<void>> _finalizar() async {
    if (empresa == null || evaluador == null || cultivo == null) {
      return const Result.error(AppFailure(FailureKind.validacion, 'Seleccione el evaluador'));
    }
    await _config.guardar(
      AppConfig(
        apiUrl: apiUrl.trim(),
        empresaId: empresa!.id,
        empresaNombre: empresa!.nombre,
        evaluadorId: evaluador!.id,
        evaluadorNombre: evaluador!.nombreVisible,
        cultivoId: cultivo!.id,
      ),
    );
    final r = await _catalogos.descargar(cultivo!.id);
    if (r is Error<void>) return r;
    await _lotes.refrescar();
    await _evaluaciones.refrescar();
    return const Result.ok(null);
  }
}
