import '../models/evaluacion.dart';
import '../models/formulario.dart';

/// Pasos del wizard de evaluación (para ubicar cada problema en su paso).
enum PasoEvaluacion {
  general('Datos'),
  muestras('Muestras'),
  sensoriales('Sensoriales'),
  sanidad('Sanidad'),
  resumen('Resumen');

  const PasoEvaluacion(this.titulo);

  final String titulo;
}

class ProblemaEvaluacion {
  const ProblemaEvaluacion(this.paso, this.mensaje);

  final PasoEvaluacion paso;
  final String mensaje;

  @override
  String toString() => '${paso.titulo}: $mensaje';
}

/// Reglas de negocio de la evaluación. Replican las del backend (ReglasEvaluacion.java) para
/// avisar al evaluador en campo, sin conexión, antes de sincronizar.
abstract final class ReglasEvaluacion {
  static const _tolerancia = 0.005;

  /// Reglas que se validan en cada guardado.
  static List<ProblemaEvaluacion> validarContenido(EvaluacionBorrador ev, FormularioEvaluacion form) {
    final problemas = <ProblemaEvaluacion>[];
    if (ev.evaluadorId == null) {
      problemas.add(const ProblemaEvaluacion(PasoEvaluacion.general, 'Seleccione el evaluador'));
    }
    for (final m in ev.muestras) {
      if (m.calidad.isNotEmpty && (m.totalCalidad - 100).abs() > _tolerancia) {
        problemas.add(
          ProblemaEvaluacion(
            PasoEvaluacion.muestras,
            'Muestra ${m.numero}: la calidad debe sumar 100% (suma ${m.totalCalidad.toStringAsFixed(2)}%)',
          ),
        );
      }
      final fueraDeRango = [...m.calidad.values, ...m.calibres.values].any((v) => v < 0 || v > 100);
      if (fueraDeRango) {
        problemas.add(
          ProblemaEvaluacion(PasoEvaluacion.muestras, 'Muestra ${m.numero}: los % deben estar entre 0 y 100'),
        );
      }
    }
    final excluyentes = form.tiposDano.where((d) => d.esExcluyente && ev.danos.contains(d.id));
    if (excluyentes.isNotEmpty && ev.danos.length > 1) {
      problemas.add(
        ProblemaEvaluacion(
          PasoEvaluacion.sensoriales,
          '"${excluyentes.first.etiqueta}" no puede marcarse junto a otros daños',
        ),
      );
    }
    for (final e in ev.sanidad.entries) {
      final p = e.value.porcentaje;
      if (e.value.presente && p != null && (p < 0 || p > 100)) {
        final nombre = form.buscar(e.key)?.etiqueta ?? 'Enfermedad';
        problemas.add(ProblemaEvaluacion(PasoEvaluacion.sanidad, '$nombre: el % debe estar entre 0 y 100'));
      }
    }
    return problemas;
  }

  /// Reglas adicionales para cerrar la evaluación (debe estar completa).
  static List<ProblemaEvaluacion> validarCierre(EvaluacionBorrador ev, FormularioEvaluacion form) {
    final problemas = validarContenido(ev, form);
    if (ev.muestras.isEmpty) {
      problemas.add(const ProblemaEvaluacion(PasoEvaluacion.muestras, 'Registre al menos una muestra'));
    }
    for (final m in ev.muestras) {
      final muestra = 'Muestra ${m.numero}';
      if (m.calidad.isEmpty) {
        problemas.add(ProblemaEvaluacion(PasoEvaluacion.muestras, '$muestra: falta el factor de calidad'));
      }
      // Calibres: elegidos del catálogo por muestra; deben sumar 100% (se permiten rangos superpuestos).
      if (m.calibres.isEmpty) {
        problemas.add(ProblemaEvaluacion(PasoEvaluacion.muestras, '$muestra: elija al menos un calibre'));
        continue;
      }
      for (final id in m.calibres.keys.where((id) => m.calibres[id] == 0)) {
        final codigo = form.buscar(id)?.codigo ?? 'un calibre';
        problemas.add(ProblemaEvaluacion(PasoEvaluacion.muestras, '$muestra: ingrese el % de $codigo'));
      }
      if ((m.totalCalibres - 100).abs() > _tolerancia) {
        problemas.add(
          ProblemaEvaluacion(
            PasoEvaluacion.muestras,
            '$muestra: los calibres deben sumar 100% (suma ${_numero(m.totalCalibres)}%)',
          ),
        );
      }
    }
    final sinResponder = form.enfermedades.where((e) => !ev.sanidad.containsKey(e.id));
    for (final e in sinResponder) {
      problemas.add(ProblemaEvaluacion(PasoEvaluacion.sanidad, '${e.etiqueta}: responda SI o NO'));
    }
    return problemas;
  }

  static String _numero(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
