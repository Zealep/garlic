import '../models/evaluacion.dart';
import '../models/lote.dart';

/// Seguimiento de lotes: cuándo toca volver al campo (fecha de corte) y cómo quedó la última evaluación.
abstract final class SeguimientoLotes {
  /// Días que faltan para el corte (negativo = ya pasó; null = sin fecha). Cuenta días calendario.
  static int? diasParaCorte(Lote lote, DateTime hoy) {
    final corte = lote.fechaCorte;
    if (corte == null) return null;
    return DateTime(corte.year, corte.month, corte.day).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
  }

  /// "Hoy", "Mañana", "En 5 días", "Hace 2 días".
  static String textoCorte(int dias) => switch (dias) {
    0 => 'Corte hoy',
    1 => 'Corte mañana',
    -1 => 'Corte fue ayer',
    > 1 => 'Corte en $dias días',
    _ => 'Corte hace ${-dias} días',
  };

  /// Lotes activos con corte entre [atraso] días atrás y [dias] días adelante, del más próximo al más lejano.
  /// Los atrasados primero: son los que más urge cerrar con el agricultor.
  static List<Lote> proximosCortes(List<Lote> lotes, DateTime hoy, {int dias = 14, int atraso = 7}) {
    final lista = [
      for (final l in lotes)
        if (l.activo)
          if (diasParaCorte(l, hoy) case final d? when d >= -atraso && d <= dias) l,
    ];
    lista.sort((a, b) => diasParaCorte(a, hoy)!.compareTo(diasParaCorte(b, hoy)!));
    return lista;
  }

  /// Última evaluación de cada lote (la más reciente por fecha).
  static Map<String, EvaluacionResumen> ultimaPorLote(List<EvaluacionResumen> evaluaciones) {
    final r = <String, EvaluacionResumen>{};
    for (final e in evaluaciones) {
      final actual = r[e.loteId];
      if (actual == null || e.fecha.isAfter(actual.fecha)) r[e.loteId] = e;
    }
    return r;
  }
}
