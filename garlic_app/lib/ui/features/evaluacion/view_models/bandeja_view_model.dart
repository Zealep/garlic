import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/lote.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Bandeja de evaluaciones (borradores y cerradas).
class BandejaViewModel extends ChangeNotifier {
  BandejaViewModel({required EvaluacionesRepository evaluaciones, required LotesRepository lotes}) {
    refrescar = Command(() async {
      final r = await evaluaciones.refrescar();
      return r is Error<void> ? r : const Result.ok(null);
    });
    _subs = [
      evaluaciones.observar().listen((e) {
        _todas = e;
        notifyListeners();
      }),
      lotes.observar().listen((l) {
        lotes_ = l;
        notifyListeners();
      }),
    ];
  }

  late final List<StreamSubscription<Object?>> _subs;
  late final Command<void> refrescar;
  List<EvaluacionResumen> _todas = const [];
  List<Lote> lotes_ = const [];
  EstadoEvaluacion? filtro;

  List<EvaluacionResumen> get evaluaciones =>
      filtro == null ? _todas : _todas.where((e) => e.estado == filtro).toList();

  int cuenta(EstadoEvaluacion? estado) =>
      estado == null ? _todas.length : _todas.where((e) => e.estado == estado).length;

  void filtrar(EstadoEvaluacion? estado) {
    filtro = estado;
    notifyListeners();
  }

  // ------------------------------------------------------------------ comparar

  /// Modo selección para comparar dos evaluaciones cerradas.
  bool comparando = false;

  /// Ids elegidos, en el orden en que se marcaron (A, B).
  List<String> seleccion = const [];

  void alternarComparar() {
    comparando = !comparando;
    seleccion = const [];
    notifyListeners();
  }

  /// Marca o desmarca. Solo cerradas (devuelve false si no se puede); con dos marcadas, una tercera
  /// reemplaza a la más antigua.
  bool seleccionar(EvaluacionResumen e) {
    if (e.estado != EstadoEvaluacion.cerrada) return false;
    seleccion = alternar(seleccion, e.id);
    notifyListeners();
    return true;
  }

  @visibleForTesting
  static List<String> alternar(List<String> seleccion, String id) =>
      seleccion.contains(id)
          ? seleccion.where((x) => x != id).toList()
          : [...seleccion, id].skip(seleccion.length >= 2 ? 1 : 0).toList();

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    refrescar.dispose();
    super.dispose();
  }
}
