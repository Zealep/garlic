import 'package:intl/intl.dart';

/// Formatos de presentación en español (Perú).
abstract final class Formato {
  static final _fecha = DateFormat('d MMM yyyy', 'es');
  static final _fechaCorta = DateFormat('d MMM', 'es');
  static final _fechaIso = DateFormat('yyyy-MM-dd');
  static final _pct = NumberFormat('##0.##', 'es');
  static final _soles = NumberFormat('#,##0.00', 'es');
  static final _precio = NumberFormat('#,##0.00##', 'es');
  static final _kg = NumberFormat('#,##0.##', 'es');

  static String fecha(DateTime? d) => d == null ? '—' : _fecha.format(d);

  static String fechaCorta(DateTime? d) => d == null ? '—' : _fechaCorta.format(d);

  static String fechaIso(DateTime d) => _fechaIso.format(d);

  static DateTime? parseFecha(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  static String porcentaje(num? v) => v == null ? '—' : '${_pct.format(v)}%';

  /// Monto en soles: "S/ 83 160,00".
  static String soles(num? v) => v == null ? '—' : 'S/ ${_soles.format(v)}';

  /// Precio por kg con hasta 4 decimales: "S/ 2,8943".
  static String precioKg(num? v) => v == null ? '—' : 'S/ ${_precio.format(v)}';

  /// Peso: "29 700 kg".
  static String kg(num? v) => v == null ? '—' : '${_kg.format(v)} kg';

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
