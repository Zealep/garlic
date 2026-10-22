import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/compra_repository.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
import '../../../../data/repositories/lotes_repository.dart';
import '../../../../domain/models/catalogo.dart';
import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/formulario.dart';
import '../../../../domain/models/lote.dart';
import '../../../../domain/use_cases/comparacion_evaluaciones.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Una de las dos evaluaciones comparadas, con su lote y lo que se sabe de su compra.
class LadoComparacion {
  const LadoComparacion({required this.evaluacion, required this.lote, this.resumen, this.precioPactado});

  final EvaluacionBorrador evaluacion;
  final Lote lote;

  /// Fila de la bandeja (nombre del evaluador); puede faltar si aún no se descargó.
  final EvaluacionResumen? resumen;

  /// Precio ya pactado para el lote (si se fijó en el equipo).
  final double? precioPactado;
}

/// Compara dos evaluaciones (de lotes distintos o del mismo) para decidir cuál conviene.
/// Los precios base son comunes a ambas, así el valor por kg es comparable.
class ComparacionViewModel extends ChangeNotifier {
  ComparacionViewModel({
    required this.idA,
    required this.idB,
    required EvaluacionesRepository evaluaciones,
    required LotesRepository lotes,
    required CatalogosRepository catalogos,
    required CompraRepository compra,
  }) : _evaluaciones = evaluaciones,
       _lotes = lotes,
       _catalogos = catalogos,
       _compra = compra {
    cargar = Command(_cargar);
    unawaited(cargar.execute());
  }

  final String idA;
  final String idB;
  final EvaluacionesRepository _evaluaciones;
  final LotesRepository _lotes;
  final CatalogosRepository _catalogos;
  final CompraRepository _compra;

  late final Command<void> cargar;

  FormularioEvaluacion? formulario;
  LadoComparacion? a;
  LadoComparacion? b;

  /// Precios base por clase de calidad (arrancan con los últimos usados en una fijación).
  Map<String, double> preciosBase = {};
  double gastoLlenado = 0;

  bool get listo => formulario != null && a != null && b != null;

  List<CatalogoItem> get clasesCalidad => formulario?.clasesCalidad ?? const [];

  ComparacionEvaluaciones? get comparacion =>
      listo
          ? ComparacionEvaluaciones.de(
            a!.evaluacion,
            b!.evaluacion,
            formulario!,
            preciosBase: preciosBase,
            gastoLlenado: gastoLlenado,
          )
          : null;

  Future<Result<void>> _cargar() async {
    formulario = _catalogos.formulario;
    if (formulario == null) {
      return const Result.error(AppFailure(FailureKind.noEncontrado, 'Faltan los catálogos. Sincroniza primero.'));
    }
    final resumenes = {for (final e in await _evaluaciones.observar().first) e.id: e};
    final lados = <LadoComparacion>[];
    for (final id in [idA, idB]) {
      final r = await _evaluaciones.cargar(id);
      if (r case Error(:final failure)) {
        return Result.error(
          AppFailure(failure.kind, 'No se pudo leer una evaluación (${failure.message}). Conéctate para descargarla.'),
        );
      }
      final ev = (r as Ok<EvaluacionBorrador>).value;
      final lote = await _lotes.obtener(ev.loteId);
      if (lote == null) {
        return const Result.error(AppFailure(FailureKind.noEncontrado, 'No se encontró el lote. Sincroniza primero.'));
      }
      final compra = await _compra.observar(lote.id).first;
      lados.add(
        LadoComparacion(
          evaluacion: ev,
          lote: lote,
          resumen: resumenes[id],
          precioPactado: compra.fijacion?.precioPactado,
        ),
      );
    }
    final ids = clasesCalidad.map((c) => c.id).toSet();
    preciosBase = {
      for (final e in (await _compra.ultimosPreciosBase()).entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
    a = lados[0];
    b = lados[1];
    notifyListeners();
    return const Result.ok(null);
  }

  void intercambiar() {
    final previo = a;
    a = b;
    b = previo;
    notifyListeners();
  }

  void setPrecioBase(String claseId, double? valor) {
    if (valor == null) {
      preciosBase.remove(claseId);
    } else {
      preciosBase[claseId] = valor;
    }
    notifyListeners();
  }

  void setGastoLlenado(double? v) {
    gastoLlenado = v ?? 0;
    notifyListeners();
  }

  @override
  void dispose() {
    cargar.dispose();
    super.dispose();
  }
}
