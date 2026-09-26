import 'package:intl/intl.dart';

/// Formatos de presentación en español (Perú).
abstract final class Formato {
  static final _fecha = DateFormat('d MMM yyyy', 'es');
  static final _fechaCorta = DateFormat('d MMM', 'es');
  static final _fechaIso = DateFormat('yyyy-MM-dd');
  static final _pct = NumberFormat('##0.##', 'es');

  static String fecha(DateTime? d) => d == null ? '—' : _fecha.format(d);

  static String fechaCorta(DateTime? d) => d == null ? '—' : _fechaCorta.format(d);

  static String fechaIso(DateTime d) => _fechaIso.format(d);

  static DateTime? parseFecha(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  static String porcentaje(num? v) => v == null ? '—' : '${_pct.format(v)}%';

  /// "hace 5 min", "hace 2 h", o la fecha.
  static String relativo(DateTime? d) {
    if (d == null) return 'nunca';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return fecha(d);
  }
}
