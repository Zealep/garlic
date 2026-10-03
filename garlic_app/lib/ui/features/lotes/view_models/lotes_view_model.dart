import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/compra_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/compra.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/lote.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

class LotesViewModel extends ChangeNotifier {
  LotesViewModel({required LotesRepository lotes}) : _lotes = lotes {
    refrescar = Command(_lotes.refrescar);
    _sub = lotes.observar().listen((l) {
      _todos = l;
      notifyListeners();
    });
  }

  final LotesRepository _lotes;
  late final StreamSubscription<List<Lote>> _sub;
  late final Command<void> refrescar;

  List<Lote> _todos = const [];
  String _q = '';
  bool _soloActivos = true;

  String get busqueda => _q;
  bool get soloActivos => _soloActivos;
  int get total => _todos.length;

  List<Lote> get lotes {
    final q = _q.trim().toLowerCase();
    return _todos
        .where((l) => !_soloActivos || l.activo)
        .where(
          (l) =>
              q.isEmpty ||
              '${l.codigo} ${l.zona} ${l.agricultor.nombres} ${l.variedad.texto}'.toLowerCase().contains(q),
        )
        .toList();
  }

  void buscar(String q) {
    _q = q;
    notifyListeners();
  }

  void alternarActivos(bool v) {
    _soloActivos = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    refrescar.dispose();
    super.dispose();
  }
}

class LoteDetalleViewModel extends ChangeNotifier {
  LoteDetalleViewModel({
    required String loteId,
    required LotesRepository lotes,
    required EvaluacionesRepository evaluaciones,
    required CompraRepository compra,
  }) {
    _subs = [
      compra.observar(loteId).listen((c) {
        this.compra = c;
        notifyListeners();
      }),
      lotes.observarUno(loteId).listen((l) {
        lote = l;
        cargando = false;
        notifyListeners();
      }),
      evaluaciones.observar(loteId: loteId).listen((e) {
        this.evaluaciones = e;
        notifyListeners();
      }),
    ];
    refrescar = Command(() async {
      final r = await lotes.refrescar();
      await evaluaciones.refrescar();
      await compra.refrescar(loteId);
      return r is Error<void> ? r : const Result.ok(null);
    });
  }

  late final List<StreamSubscription<Object?>> _subs;
  late final Command<void> refrescar;

  Lote? lote;
  bool cargando = true;
  List<EvaluacionResumen> evaluaciones = const [];
  CompraLote? compra;

  EvaluacionResumen? get borradorAbierto =>
      evaluaciones.where((e) => e.estado == EstadoEvaluacion.borrador).firstOrNull;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    refrescar.dispose();
    super.dispose();
  }
}
