import '../models/evaluacion.dart';
import '../models/formulario.dart';

/// Pasos del wizard de evaluación (para ubicar cada problema en su paso). Calidad, calibre,
/// sensoriales y sanidad se llenan dentro de cada muestra.
enum PasoEvaluacion {
  general('Datos'),
  muestras('Muestras'),
  resumen('Resumen');

  const PasoEvaluacion(this.titulo);

  final String titulo;
}

class ProblemaEvaluacion {
  const ProblemaEvaluacion(this.paso, this.mensaje, {this.muestra});

  final PasoEvaluacion paso;
  final String mensaje;

  /// Número de la muestra con el problema (para llevar al evaluador a ella).
  final int? muestra;

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
      void problema(String mensaje) => problemas.add(
        ProblemaEvaluacion(PasoEvaluacion.muestras, 'Muestra ${m.numero}: $mensaje', muestra: m.numero),
      );

      if (m.calidad.isNotEmpty && (m.totalCalidad - 100).abs() > _tolerancia) {
        problema('la calidad debe sumar 100% (suma ${m.totalCalidad.toStringAsFixed(2)}%)');
      }
      final fueraDeRango = [...m.calidad.values, ...m.calibres.values].any((v) => v < 0 || v > 100);
      if (fueraDeRango) problema('los % deben estar entre 0 y 100');

      final excluyentes = form.tiposDano.where((d) => d.esExcluyente && m.danos.containsKey(d.id));
      if (excluyentes.isNotEmpty && m.danos.length > 1) {
        problema('"${excluyentes.first.etiqueta}" no puede marcarse junto a otros daños');
      }
      for (final e in m.danos.entries) {
        final d = e.value;
        if (d.total != null && d.afectados != null && d.afectados! > d.total!) {
          problema('${form.buscar(e.key)?.etiqueta ?? 'Daño'}: los frutos con problema no pueden ser más que el total');
        }
      }
      for (final e in m.sanidad.entries) {
        final p = e.value.porcentaje;
        if (e.value.presente && p != null && (p < 0 || p > 100)) {
          problema('${form.buscar(e.key)?.etiqueta ?? 'Enfermedad'}: el % debe estar entre 0 y 100');
        }
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
      void problema(String mensaje) => problemas.add(
        ProblemaEvaluacion(PasoEvaluacion.muestras, 'Muestra ${m.numero}: $mensaje', muestra: m.numero),
      );

      if (m.calidad.isEmpty) problema('falta el factor de calidad');
      // Calibres: elegidos del catálogo por muestra; deben sumar 100% (se permiten rangos superpuestos).
      if (m.calibres.isEmpty) {
        problema('elija al menos un calibre');
      } else {
        for (final id in m.calibres.keys.where((id) => m.calibres[id] == 0)) {
          problema('ingrese el % de ${form.buscar(id)?.codigo ?? 'un calibre'}');
        }
        if ((m.totalCalibres - 100).abs() > _tolerancia) {
          problema('los calibres deben sumar 100% (suma ${_numero(m.totalCalibres)}%)');
        }
      }
      for (final tipo in form.tiposDano.where((d) => d.pideCantidades && m.danos.containsKey(d.id))) {
        final d = m.danos[tipo.id]!;
        if (d.total == null || d.afectados == null) {
          problema('${tipo.etiqueta}: ingrese los frutos total y con problema');
        }
      }
      for (final e in form.enfermedades.where((e) => !m.sanidad.containsKey(e.id))) {
        problema('${e.etiqueta}: responda SI o NO');
      }
    }
    return problemas;
  }

  static String _numero(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
