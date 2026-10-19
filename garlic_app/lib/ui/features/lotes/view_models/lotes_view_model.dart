import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/compra_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/compra.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/lote.dart';
import '../../../../domain/use_cases/seguimiento_lotes.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

class LotesViewModel extends ChangeNotifier {
  LotesViewModel({required LotesRepository lotes, required EvaluacionesRepository evaluaciones}) : _lotes = lotes {
    refrescar = Command(_lotes.refrescar);
    _subs = [
      lotes.observar().listen((l) {
        _todos = l;
        notifyListeners();
      }),
      evaluaciones.observar().listen((e) {
        _ultima = SeguimientoLotes.ultimaPorLote(e);
        notifyListeners();
      }),
    ];
  }

  final LotesRepository _lotes;
  late final List<StreamSubscription<Object?>> _subs;
  late final Command<void> refrescar;

  List<Lote> _todos = const [];
  Map<String, EvaluacionResumen> _ultima = const {};
  String _q = '';
  bool _soloActivos = true;
  bool _proximosCortes = false;

  String get busqueda => _q;
  bool get soloActivos => _soloActivos;
  bool get proximosCortes => _proximosCortes;
  int get total => _todos.length;

  /// Última evaluación del lote (su resultado y % de primera).
  EvaluacionResumen? ultimaEvaluacion(String loteId) => _ultima[loteId];

  int? diasParaCorte(Lote l) => SeguimientoLotes.diasParaCorte(l, DateTime.now());

  /// Solo los lotes con corte cercano (7 días atrás a 14 adelante), del más urgente al más lejano.
  void alternarProximosCortes(bool v) {
    _proximosCortes = v;
    notifyListeners();
  }

  List<Lote> get lotes {
    final q = _q.trim().toLowerCase();
    final base = _proximosCortes ? SeguimientoLotes.proximosCortes(_todos, DateTime.now()) : _todos;
    return base
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
    for (final s in _subs) {
      s.cancel();
    }
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
