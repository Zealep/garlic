import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/catalogo.dart';
import 'package:garlic_app/domain/models/evaluacion.dart';
import 'package:garlic_app/domain/models/formulario.dart';
import 'package:garlic_app/domain/use_cases/reglas_evaluacion.dart';

const primera = 'c-primera';
const abiertos = 'c-abiertos';
const cal4550 = 'cal-45-50';
const noContiene = 'd-no-contiene';
const cerosa = 'd-cerosa';
const fusarium = 'e-fusarium';
const raizRosada = 'e-raiz';

final formulario = FormularioEvaluacion(
  cultivoId: 'ajo',
  clasesCalidad: const [
    CatalogoItem(id: primera, codigo: 'PRIMERA', nombre: 'PRIMERA', orden: 1),
    CatalogoItem(id: abiertos, codigo: 'ABIERTOS', nombre: 'ABIERTOS', orden: 2),
  ],
  calibres: const [CatalogoItem(id: cal4550, codigo: '45/50', nombre: '45/50')],
  tiposHumedad: const [],
  tiposEmpaste: const [],
  tiposDano: const [
    CatalogoItem(id: cerosa, codigo: 'CEROSA', nombre: 'PARALISIS CEROSA'),
    CatalogoItem(id: noContiene, codigo: 'NO_CONTIENE', nombre: 'NO CONTIENE', esExcluyente: true),
  ],
  enfermedades: const [
    CatalogoItem(id: raizRosada, codigo: 'RAIZ_ROSADA', nombre: 'RAIZ ROSADA', evaluarEnCampo: true),
    CatalogoItem(id: fusarium, codigo: 'FUSARIUM', nombre: 'FUSARIUM', evaluarEnCampo: true),
  ],
);

/// Lote modelo del Excel: PRIMERA 80/85/75 y calibre 45/50 13/10/20.
EvaluacionBorrador loteModelo() => EvaluacionBorrador(
  id: 'ev-1',
  loteId: 'lote-1',
  evaluadorId: 'u-1',
  fecha: DateTime(2025, 10, 10),
  muestras: [
    MuestraBorrador(numero: 1, calidad: {primera: 80, abiertos: 20}, calibres: {cal4550: 13}),
    MuestraBorrador(numero: 2, calidad: {primera: 85, abiertos: 15}, calibres: {cal4550: 10}),
    MuestraBorrador(numero: 3, calidad: {primera: 75, abiertos: 25}, calibres: {cal4550: 20}),
  ],
  danos: {noContiene},
  sanidad: {raizRosada: SanidadBorrador(presente: false), fusarium: SanidadBorrador(presente: true, porcentaje: 5)},
);

void main() {
  group('Promedios (columna PROM del protocolo)', () {
    test('coinciden con el Excel', () {
      final ev = loteModelo();
      expect(ev.promediosCalidad()[primera], 80.0);
      expect(ev.promediosCalidad()[abiertos], 20.0);
      expect(ev.promediosCalibres()[cal4550], 14.33);
    });

    test('solo promedian las muestras que registran la opción', () {
      final ev = loteModelo()..muestras.add(MuestraBorrador(numero: 4));
      expect(ev.promediosCalidad()[primera], 80.0);
    });
  });

  group('Serialización (formato request del API)', () {
    test('ida y vuelta conserva todo el contenido', () {
      final original = loteModelo()..humedad['h-1'] = NivelHumedad.alta;
      final json = original.toRequestJson();
      final copia = EvaluacionBorrador.fromRequestJson(json, loteId: 'lote-1');

      expect(copia.muestras.map((m) => m.calidad[primera]), [80, 85, 75]);
      expect(copia.humedad['h-1'], NivelHumedad.alta);
      expect(copia.danos, {noContiene});
      expect(copia.sanidad[fusarium]!.porcentaje, 5);
      expect(json['fechaEvaluacion'], '2025-10-10');
    });

    test('no envía % de una enfermedad marcada como NO', () {
      final ev = loteModelo()..sanidad[raizRosada] = SanidadBorrador(presente: false, porcentaje: 7);
      final sanidad = (ev.toRequestJson()['sanidad']! as List).cast<Map<String, Object?>>();
      expect(sanidad.firstWhere((s) => s['enfermedadId'] == raizRosada)['porcentaje'], isNull);
    });
  });

  group('Reglas de negocio', () {
    test('el lote modelo está listo para cerrar', () {
      expect(ReglasEvaluacion.validarCierre(loteModelo(), formulario), isEmpty);
    });

    test('calidad que no suma 100% se reporta en el paso Muestras', () {
      final ev = loteModelo();
      ev.muestras.first.calidad[abiertos] = 10;
      final problemas = ReglasEvaluacion.validarContenido(ev, formulario);
      expect(problemas.single.paso, PasoEvaluacion.muestras);
      expect(problemas.single.mensaje, contains('Muestra 1'));
    });

    test('"No contiene" junto a otro daño es inválido', () {
      final ev = loteModelo()..danos.add(cerosa);
      expect(
        ReglasEvaluacion.validarContenido(ev, formulario).map((p) => p.paso),
        contains(PasoEvaluacion.sensoriales),
      );
    });

    test('para cerrar hay que responder todas las enfermedades de campo', () {
      final ev = loteModelo()..sanidad.remove(fusarium);
      final problemas = ReglasEvaluacion.validarCierre(ev, formulario);
      expect(problemas.single.paso, PasoEvaluacion.sanidad);
    });

    test('sin evaluador no se puede guardar', () {
      final ev = loteModelo()..evaluadorId = null;
      expect(ReglasEvaluacion.validarContenido(ev, formulario).first.paso, PasoEvaluacion.general);
    });
  });
}
