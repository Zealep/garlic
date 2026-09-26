import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/catalogo.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Primer uso: servidor → empresa → evaluador → descarga de catálogos para trabajar sin red.
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
    elegirEmpresa = Command1(_elegirEmpresa);
    finalizar = Command(_finalizar);
    final actual = config.config;
    apiUrl = actual?.apiUrl ?? (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');
  }

  final ConfigRepository _config;
  final CatalogosRepository _catalogos;
  final LotesRepository _lotes;
  final EvaluacionesRepository _evaluaciones;

  late final Command<List<EmpresaOpcion>> conectar;
  late final Command1<void, EmpresaOpcion> elegirEmpresa;
  late final Command<void> finalizar;

  late String apiUrl;
  List<EmpresaOpcion> empresas = const [];
  EmpresaOpcion? empresa;
  List<PersonaItem> evaluadores = const [];
  PersonaItem? evaluador;
  CatalogoItem? cultivo;

  int get paso => empresa == null ? (empresas.isEmpty ? 0 : 1) : 2;

  Future<Result<List<EmpresaOpcion>>> _conectar() async {
    final r = await _config.probarServidor(apiUrl.trim());
    if (r case Ok(:final value)) {
      empresas = value;
      empresa = null;
      notifyListeners();
    }
    return r;
  }

  Future<Result<void>> _elegirEmpresa(EmpresaOpcion e) async {
    final r = await _config.datosEmpresa(apiUrl.trim(), e.id);
    switch (r) {
      case Ok(:final value):
        empresa = e;
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
    if (empresa != null) {
      empresa = null;
    } else {
      empresas = const [];
    }
    notifyListeners();
  }

  Future<Result<void>> _finalizar() async {
    if (empresa == null || evaluador == null || cultivo == null) {
      return const Result.error(AppFailure(FailureKind.validacion, 'Seleccione empresa y evaluador'));
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
