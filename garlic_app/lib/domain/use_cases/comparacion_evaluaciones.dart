import '../models/evaluacion.dart';
import '../models/formulario.dart';
import 'calculo_compra.dart';

enum Ganador { a, b, empate }

/// Una fila de la comparación. `ganador` solo se calcula donde la dirección es inequívoca
/// (más % de primera, más valor por kg, menos sanidad y daños); null = solo se muestra.
class FilaComparacion {
  const FilaComparacion({required this.id, required this.etiqueta, required this.a, required this.b, this.ganador});

  final String id;
  final String etiqueta;
  final double? a;
  final double? b;
  final Ganador? ganador;

  /// B − A (null si falta alguno).
  double? get diferencia => a == null || b == null ? null : CalculoCompra.redondear(b! - a!, 4);
}

/// Comparación lado a lado de dos evaluaciones para decidir qué lote conviene. No da un puntaje global
/// (sus pesos los tendría que definir el cliente): resalta el mejor valor por fila y calcula el valor
/// técnico por kg de ambas con los mismos precios base.
class ComparacionEvaluaciones {
  const ComparacionEvaluaciones._({
    required this.calidad,
    required this.calibres,
    required this.valorKg,
    required this.fijacionA,
    required this.fijacionB,
    required this.sanidadYDanos,
  });

  /// Hasta esta diferencia es empate: puntos de % y S/ por kg.
  static const umbralPorcentaje = 0.5;
  static const umbralPrecio = 0.01;

  factory ComparacionEvaluaciones.de(
    EvaluacionBorrador a,
    EvaluacionBorrador b,
    FormularioEvaluacion formulario, {
    Map<String, double> preciosBase = const {},
    double gastoLlenado = 0,
  }) {
    final promA = a.promediosCalidad(), promB = b.promediosCalidad();
    final primera = formulario.clasesCalidad.firstOrNull?.id;
    final calidad = [
      for (final id in _usados(formulario.clasesCalidad.map((c) => c.id), promA.keys, promB.keys))
        FilaComparacion(
          id: id,
          etiqueta: formulario.buscar(id)?.etiqueta ?? 'Clase retirada',
          a: promA[id] ?? 0,
          b: promB[id] ?? 0,
          ganador:
              id == primera ? _ganador(promA[id] ?? 0, promB[id] ?? 0, umbralPorcentaje, mayorEsMejor: true) : null,
        ),
    ];

    final calA = a.promediosCalibres(), calB = b.promediosCalibres();
    final calibres = [
      for (final id in _usados(formulario.calibres.map((c) => c.id), calA.keys, calB.keys))
        FilaComparacion(
          id: id,
          etiqueta: formulario.buscar(id)?.codigo ?? 'Calibre retirado',
          a: calA[id] ?? 0,
          b: calB[id] ?? 0,
        ),
    ];

    final fijA = _fijacion(a, preciosBase, gastoLlenado), fijB = _fijacion(b, preciosBase, gastoLlenado);
    final hayPrecios = preciosBase.values.any((p) => p > 0);
    final valorKg = FilaComparacion(
      id: 'valorKg',
      etiqueta: 'Valor técnico por kg',
      a: hayPrecios ? fijA.precioTecnico : null,
      b: hayPrecios ? fijB.precioTecnico : null,
      ganador: hayPrecios ? _ganador(fijA.precioTecnico, fijB.precioTecnico, umbralPrecio, mayorEsMejor: true) : null,
    );

    // la opción excluyente es "NO CONTIENE": no cuenta como daño
    final sinDano = formulario.tiposDano.where((d) => d.esExcluyente).map((d) => d.id).toSet();
    FilaComparacion menor(String id, String etiqueta, double Function(EvaluacionBorrador) valor, double umbral) {
      final (va, vb) = (valor(a), valor(b));
      return FilaComparacion(
        id: id,
        etiqueta: etiqueta,
        a: va,
        b: vb,
        ganador: _ganador(va, vb, umbral, mayorEsMejor: false),
      );
    }

    return ComparacionEvaluaciones._(
      calidad: calidad,
      calibres: calibres,
      valorKg: valorKg,
      fijacionA: fijA,
      fijacionB: fijB,
      sanidadYDanos: [
        menor('enfermedades', 'Enfermedades presentes', (e) => _presentes(e).length.toDouble(), 0),
        menor(
          'incidencia',
          'Incidencia máxima',
          (e) => _presentes(e).fold(0, (m, p) => p > m ? p : m),
          umbralPorcentaje,
        ),
        menor('danos', 'Daños registrados', (e) => e.danos.where((d) => !sinDano.contains(d)).length.toDouble(), 0),
      ],
    );
  }

  /// % promedio por clase de calidad (la primera clase tiene dirección: más es mejor).
  final List<FilaComparacion> calidad;

  /// % promedio por calibre (unión de los usados por ambas; sin dirección, depende del mercado).
  final List<FilaComparacion> calibres;

  /// Precio técnico de cada una con los mismos precios base (null sin precios).
  final FilaComparacion valorKg;
  final ResultadoFijacion fijacionA;
  final ResultadoFijacion fijacionB;

  /// Menos es mejor en todas.
  final List<FilaComparacion> sanidadYDanos;

  List<FilaComparacion> get conDireccion =>
      [...calidad, valorKg, ...sanidadYDanos].where((f) => f.ganador != null).toList();

  int ganadas(Ganador g) => conDireccion.where((f) => f.ganador == g).length;

  /// Ids en el orden del catálogo y luego los que ya no están en él.
  static List<String> _usados(Iterable<String> orden, Iterable<String> a, Iterable<String> b) {
    final usados = {...a, ...b};
    final lista = [
      for (final id in orden)
        if (usados.contains(id)) id,
    ];
    return [...lista, ...usados.where((id) => !lista.contains(id))];
  }

  static ResultadoFijacion _fijacion(EvaluacionBorrador e, Map<String, double> precios, double llenado) {
    final muestras = [...e.muestras]..sort((x, y) => x.numero.compareTo(y.numero));
    return CalculoCompra.fijacion(precios, [for (final m in muestras) m.calidad], llenado);
  }

  /// % de cada enfermedad presente (sin % registrado cuenta como 0).
  static List<double> _presentes(EvaluacionBorrador e) => [
    for (final s in e.sanidad.values)
      if (s.presente) s.porcentaje ?? 0,
  ];

  static Ganador _ganador(double a, double b, double umbral, {required bool mayorEsMejor}) {
    final d = b - a;
    if (d.abs() <= umbral) return Ganador.empate;
    return (d > 0) == mayorEsMejor ? Ganador.b : Ganador.a;
  }
}
