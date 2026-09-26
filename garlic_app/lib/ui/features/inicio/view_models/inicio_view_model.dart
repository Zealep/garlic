import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../data/repositories/sync_repository.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/lote.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

class InicioViewModel extends ChangeNotifier {
  InicioViewModel({
    required LotesRepository lotes,
    required EvaluacionesRepository evaluaciones,
    required SyncRepository sync,
    required CatalogosRepository catalogos,
    required ConfigRepository config,
  }) : _sync = sync,
       _catalogos = catalogos,
       _lotes = lotes,
       _evaluaciones = evaluaciones,
       _config = config {
    refrescar = Command(_refrescar);
    _subs = [
      lotes.observar().listen((l) {
        _listaLotes = l;
        notifyListeners();
      }),
      evaluaciones.observar().listen((e) {
        _listaEvaluaciones = e;
        notifyListeners();
      }),
    ];
    unawaited(refrescar.execute());
  }

  final SyncRepository _sync;
  final CatalogosRepository _catalogos;
  final LotesRepository _lotes;
  final EvaluacionesRepository _evaluaciones;
  final ConfigRepository _config;
  late final List<StreamSubscription<Object?>> _subs;
  late final Command<void> refrescar;

  List<Lote> _listaLotes = const [];
  List<EvaluacionResumen> _listaEvaluaciones = const [];

  String get evaluador => _config.config?.evaluadorNombre.split(' ').first ?? '';
  String get empresa => _config.config?.empresaNombre ?? '';

  List<Lote> get lotesActivos => _listaLotes.where((l) => l.activo).toList();
  int get borradores => _listaEvaluaciones.where((e) => e.estado == EstadoEvaluacion.borrador).length;
  int get cerradas => _listaEvaluaciones.where((e) => e.estado == EstadoEvaluacion.cerrada).length;
  List<EvaluacionResumen> get recientes => _listaEvaluaciones.take(6).toList();

  /// Evaluaciones con % de PRIMERA conocido (para el gráfico del tablero).
  List<EvaluacionResumen> get conCalidad => _listaEvaluaciones.where((e) => e.promedioPrimera != null).take(8).toList();

  /// Promedio de PRIMERA de las evaluaciones cerradas (las que cuentan para decidir).
  double? get calidadPromedio {
    final v =
        _listaEvaluaciones
            .where((e) => e.estado == EstadoEvaluacion.cerrada && e.promedioPrimera != null)
            .map((e) => e.promedioPrimera!)
            .toList();
    return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
  }

  Lote? lote(String id) => _listaLotes.where((l) => l.id == id).firstOrNull;

  Future<Result<void>> _refrescar() async {
    await _sync.sincronizar();
    final cultivo = _config.config?.cultivoId;
    if (cultivo != null) await _catalogos.descargar(cultivo);
    final r = await _lotes.refrescar();
    await _evaluaciones.refrescar();
    return r;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    refrescar.dispose();
    super.dispose();
  }
}
