import 'catalogo.dart';

/// Opciones activas de cada factor de calidad para el cultivo (endpoint /evaluaciones/formulario).
/// Cada empresa las configura; la app dibuja el formulario a partir de aquí.
class FormularioEvaluacion {
  const FormularioEvaluacion({
    required this.cultivoId,
    required this.clasesCalidad,
    required this.calibres,
    required this.tiposHumedad,
    required this.tiposEmpaste,
    required this.tiposDano,
    required this.enfermedades,
  });

  factory FormularioEvaluacion.fromJson(Map<String, Object?> json) {
    List<CatalogoItem> lista(String clave) =>
        ((json[clave] as List<Object?>?) ?? const [])
            .map((e) => CatalogoItem.fromJson(e! as Map<String, Object?>))
            .toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));
    return FormularioEvaluacion(
      cultivoId: json['cultivoId']! as String,
      clasesCalidad: lista('clasesCalidad'),
      calibres: lista('calibres'),
      tiposHumedad: lista('tiposHumedad'),
      tiposEmpaste: lista('tiposEmpaste'),
      tiposDano: lista('tiposDano'),
      enfermedades: lista('enfermedades'),
    );
  }

  final String cultivoId;
  final List<CatalogoItem> clasesCalidad;
  final List<CatalogoItem> calibres;
  final List<CatalogoItem> tiposHumedad;
  final List<CatalogoItem> tiposEmpaste;
  final List<CatalogoItem> tiposDano;

  /// Solo las marcadas "evaluar en campo" (SI/NO + %).
  final List<CatalogoItem> enfermedades;

  Map<String, Object?> toJson() => {
    'cultivoId': cultivoId,
    'clasesCalidad': clasesCalidad.map((e) => e.toJson()).toList(),
    'calibres': calibres.map((e) => e.toJson()).toList(),
    'tiposHumedad': tiposHumedad.map((e) => e.toJson()).toList(),
    'tiposEmpaste': tiposEmpaste.map((e) => e.toJson()).toList(),
    'tiposDano': tiposDano.map((e) => e.toJson()).toList(),
    'enfermedades': enfermedades.map((e) => e.toJson()).toList(),
  };

  CatalogoItem? buscar(String id) {
    for (final lista in [clasesCalidad, calibres, tiposHumedad, tiposEmpaste, tiposDano, enfermedades]) {
      for (final item in lista) {
        if (item.id == id) return item;
      }
    }
    return null;
  }
}
