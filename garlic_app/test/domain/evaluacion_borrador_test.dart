import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/catalogo.dart';
import 'package:garlic_app/domain/models/evaluacion.dart';
import 'package:garlic_app/domain/models/formulario.dart';
import 'package:garlic_app/domain/use_cases/reglas_evaluacion.dart';

const primera = 'c-primera';
const abiertos = 'c-abiertos';
const cal4550 = 'cal-45-50';
const cal5060 = 'cal-50-60';
const noContiene = 'd-no-contiene';
const cerosa = 'd-cerosa';
const fusarium = 'e-fusarium';
const raizRosada = 'e-raiz';
const gotas = 'h-gotas';

const formulario = FormularioEvaluacion(
  cultivoId: 'ajo',
  clasesCalidad: [
    CatalogoItem(id: primera, codigo: 'PRIMERA', nombre: 'PRIMERA', orden: 1),
    CatalogoItem(id: abiertos, codigo: 'ABIERTOS', nombre: 'ABIERTOS', orden: 2),
  ],
  calibres: [
    CatalogoItem(id: cal4550, codigo: '45/50', nombre: '45/50', orden: 1),
    CatalogoItem(id: cal5060, codigo: '50/60', nombre: '50/60', orden: 3),
  ],
  tiposHumedad: [CatalogoItem(id: gotas, codigo: 'GOTAS', nombre: 'GOTAS DENTRO')],
  tiposEmpaste: [],
  tiposDano: [
    CatalogoItem(id: cerosa, codigo: 'CEROSA', nombre: 'PARALISIS CEROSA', pideCantidades: true),
    CatalogoItem(id: noContiene, codigo: 'NO_CONTIENE', nombre: 'NO CONTIENE', esExcluyente: true),
  ],
  enfermedades: [
    CatalogoItem(id: raizRosada, codigo: 'RAIZ_ROSADA', nombre: 'RAIZ ROSADA', evaluarEnCampo: true),
    CatalogoItem(id: fusarium, codigo: 'FUSARIUM', nombre: 'FUSARIUM', evaluarEnCampo: true),
  ],
);

Map<String, SanidadBorrador> _sanidad() => {
  raizRosada: SanidadBorrador(presente: false),
  fusarium: SanidadBorrador(presente: true, porcentaje: 5),
};

/// Lote modelo del Excel: PRIMERA 80/85/75; sensoriales y sanidad en cada muestra (la 2 con parálisis 10/20).
EvaluacionBorrador loteModelo() => EvaluacionBorrador(
  id: 'ev-1',
  loteId: 'lote-1',
  evaluadorId: 'u-1',
  fecha: DateTime(2025, 10, 10),
  muestras: [
    MuestraBorrador(
      id: 'm-1',
      numero: 1,
      calidad: {primera: 80, abiertos: 20},
      calibres: {cal4550: 40, cal5060: 60},
      humedad: {gotas: true},
      danos: {noContiene: DanoBorrador()},
      sanidad: _sanidad(),
    ),
    MuestraBorrador(
      id: 'm-2',
      numero: 2,
      calidad: {primera: 85, abiertos: 15},
      calibres: {cal4550: 30, cal5060: 70},
      humedad: {gotas: false},
      danos: {cerosa: DanoBorrador(total: 20, afectados: 10)},
      sanidad: _sanidad(),
    ),
    MuestraBorrador(
      id: 'm-3',
      numero: 3,
      calidad: {primera: 75, abiertos: 25},
      calibres: {cal4550: 50, cal5060: 50},
      danos: {noContiene: DanoBorrador()},
      sanidad: {raizRosada: SanidadBorrador(presente: false), fusarium: SanidadBorrador(presente: false)},
    ),
  ],
);

void main() {
  group('Promedios (columna PROM del protocolo)', () {
    test('coinciden con el Excel', () {
      final ev = loteModelo();
      expect(ev.promediosCalidad()[primera], 80.0);
      expect(ev.promediosCalidad()[abiertos], 20.0);
      expect(ev.promediosCalibres()[cal4550], 40.0);
      expect(ev.promediosCalibres()[cal5060], 60.0);
    });

    test('solo promedian las muestras que registran la opción', () {
      final ev = loteModelo()..muestras.add(MuestraBorrador(numero: 4));
      expect(ev.promediosCalidad()[primera], 80.0);
    });
  });

  group('Serialización (formato request del API)', () {
    test('ida y vuelta conserva todo el contenido de cada muestra', () {
      final json = loteModelo().toRequestJson();
      final copia = EvaluacionBorrador.fromRequestJson(json, loteId: 'lote-1');

      expect(copia.muestras.map((m) => m.id), ['m-1', 'm-2', 'm-3']);
      expect(copia.muestras.map((m) => m.calidad[primera]), [80, 85, 75]);
      expect(copia.muestras.first.humedad[gotas], isTrue);
      expect(copia.muestras[1].humedad[gotas], isFalse);
      expect(copia.muestras.first.danos.keys, [noContiene]);
      expect(copia.muestras[1].danos[cerosa]!.porcentaje, 50);
      expect(copia.muestras.first.sanidad[fusarium]!.porcentaje, 5);
      expect(json['fechaEvaluacion'], '2025-10-10');
      expect(json.containsKey('sanidad'), isFalse); // ya no va por evaluación
    });

    test('lee la respuesta del API (ids de opción en "id")', () {
      final ev = EvaluacionBorrador.fromResponseJson({
        'id': 'ev',
        'loteId': 'l',
        'estado': 'CERRADA',
        'muestras': [
          {
            'id': 'm-9',
            'numero': 1,
            'calidad': [
              {'id': primera, 'porcentaje': 80},
            ],
            'calibres': [],
            'humedad': [
              {'id': gotas, 'presente': true},
            ],
            'empastes': [
              {'id': 'emp'},
            ],
            'danos': [
              {'id': cerosa, 'frutosTotal': 30, 'frutosAfectados': 3, 'porcentaje': 10},
            ],
            'sanidad': [
              {'id': fusarium, 'presente': true, 'porcentaje': 7},
            ],
          },
        ],
      });
      final m = ev.muestras.single;
      expect(m.id, 'm-9');
      expect(m.humedad, {gotas: true});
      expect(m.empastes, {'emp'});
      expect(m.danos[cerosa]!.porcentaje, 10);
      expect(m.sanidad[fusarium]!.porcentaje, 7);
    });

    test('no envía % de una enfermedad marcada como NO', () {
      final ev = loteModelo()..muestras.first.sanidad[raizRosada] = SanidadBorrador(presente: false, porcentaje: 7);
      final muestra = (ev.toRequestJson()['muestras']! as List).first as Map<String, Object?>;
      final sanidad = (muestra['sanidad']! as List).cast<Map<String, Object?>>();
      expect(sanidad.firstWhere((s) => s['enfermedadId'] == raizRosada)['porcentaje'], isNull);
    });
  });

  group('Muestras', () {
    test('al quitar la muestra 1 se renumeran 1..n y conservan su id', () {
      final ev = loteModelo()..quitarMuestra('m-1');
      expect(ev.muestras.map((m) => m.numero), [1, 2]);
      expect(ev.muestras.map((m) => m.id), ['m-2', 'm-3']);
      expect(ev.nuevaMuestra().numero, 3);
    });

    test('% de parálisis = frutos con problema / total', () {
      expect(DanoBorrador(total: 20, afectados: 10).porcentaje, 50);
      expect(DanoBorrador(total: 3, afectados: 1).porcentaje, 33.33);
      expect(DanoBorrador(total: 20).porcentaje, isNull);
      // promedio sobre las muestras que la cuentan
      expect(loteModelo().promediosDanos(), {cerosa: 50});
    });

    test('incidencia promedio por enfermedad (NO cuenta como 0%) y humedad SI por indicador', () {
      final ev = loteModelo();
      expect(ev.promediosSanidad()[fusarium], 3.33);
      expect(ev.promediosSanidad()[raizRosada], 0);
      expect(ev.muestrasConHumedad(), {gotas: 1});
    });

    test('copiar de la muestra anterior trae sensoriales y sanidad, sin las cantidades', () {
      final ev = loteModelo();
      final nueva = ev.nuevaMuestra()..copiarSensorialesYSanidad(ev.muestras[1]);
      expect(nueva.humedad, {gotas: false});
      expect(nueva.danos.keys, [cerosa]);
      expect(nueva.danos[cerosa]!.total, isNull);
      expect(nueva.sanidad[fusarium]!.porcentaje, 5);
      nueva.sanidad[fusarium]!.porcentaje = 9; // copia independiente
      expect(ev.muestras[1].sanidad[fusarium]!.porcentaje, 5);
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
      expect(problemas.single.muestra, 1);
      expect(problemas.single.mensaje, contains('Muestra 1'));
    });

    test('"No contiene" junto a otro daño es inválido en la muestra', () {
      final ev = loteModelo()..muestras.first.danos[cerosa] = DanoBorrador(total: 10, afectados: 1);
      expect(
        ReglasEvaluacion.validarContenido(ev, formulario).map((p) => p.mensaje),
        contains('Muestra 1: "No contiene" no puede marcarse junto a otros daños'),
      );
    });

    test('parálisis: para cerrar se piden las cantidades; con problema no supera el total', () {
      final ev = loteModelo()..muestras[1].danos[cerosa] = DanoBorrador(total: 20);
      expect(
        ReglasEvaluacion.validarCierre(ev, formulario).map((p) => p.mensaje),
        contains('Muestra 2: Paralisis cerosa: ingrese los frutos total y con problema'),
      );
      ev.muestras[1].danos[cerosa] = DanoBorrador(total: 10, afectados: 12);
      expect(
        ReglasEvaluacion.validarContenido(ev, formulario).single.mensaje,
        contains('no pueden ser más que el total'),
      );
    });

    test('para cerrar cada muestra responde todas las enfermedades de campo', () {
      final ev = loteModelo()..muestras[2].sanidad.remove(fusarium);
      final problemas = ReglasEvaluacion.validarCierre(ev, formulario);
      expect(problemas.single.mensaje, 'Muestra 3: Fusarium: responda SI o NO');
      expect(problemas.single.muestra, 3);
    });

    test('sin evaluador no se puede guardar', () {
      final ev = loteModelo()..evaluadorId = null;
      expect(ReglasEvaluacion.validarContenido(ev, formulario).first.paso, PasoEvaluacion.general);
    });
  });

  group('Sección de cada foto', () {
    EvidenciaLocal foto({String? muestraId, int? muestra}) => EvidenciaLocal(
      id: 'f',
      evaluacionId: 'ev-1',
      bytes: Uint8List(0),
      mime: 'image/jpeg',
      creado: DateTime(2025),
      muestraId: muestraId,
      muestraNumero: muestra,
    );

    test('con muestra (por id o número) pertenece a la muestra; sin muestra es general', () {
      expect(SeccionFoto.de(foto(muestraId: 'm-1')), SeccionFoto.muestra);
      expect(SeccionFoto.de(foto(muestra: 2)), SeccionFoto.muestra);
      expect(SeccionFoto.de(foto()), SeccionFoto.general);
    });
  });

  test('sensoriales y sanidad van dentro de cada muestra: el wizard tiene 3 pasos', () {
    expect(PasoEvaluacion.values.map((p) => p.titulo), ['Datos', 'Muestras', 'Resumen']);
  });

  group('Calibres elegidos por muestra (deben sumar 100%)', () {
    test('para cerrar, cada muestra debe tener calibres', () {
      final ev = loteModelo();
      ev.muestras[1].calibres.clear();
      expect(
        ReglasEvaluacion.validarCierre(ev, formulario).map((p) => p.mensaje),
        contains('Muestra 2: elija al menos un calibre'),
      );
    });

    test('para cerrar, los calibres deben sumar 100%', () {
      final ev = loteModelo();
      ev.muestras.first.calibres[cal5060] = 39.3;
      expect(
        ReglasEvaluacion.validarCierre(ev, formulario).map((p) => p.mensaje),
        contains('Muestra 1: los calibres deben sumar 100% (suma 79.30%)'),
      );
    });

    test('un calibre elegido sin % se reporta con su código', () {
      final ev = loteModelo();
      ev.muestras.first.calibres
        ..[cal4550] = 100
        ..[cal5060] = 0;
      expect(
        ReglasEvaluacion.validarCierre(ev, formulario).map((p) => p.mensaje),
        contains('Muestra 1: ingrese el % de 50/60'),
      );
    });

    test('mientras se escribe el borrador no se exige la suma (se valida al cerrar)', () {
      final ev = loteModelo();
      ev.muestras.first.calibres[cal5060] = 10;
      expect(ReglasEvaluacion.validarContenido(ev, formulario), isEmpty);
    });

    test('Completar 100% llena el calibre pendiente con lo que falta', () {
      final m = MuestraBorrador(numero: 1, calibres: {cal4550: 70, cal5060: 0});
      expect(m.faltaCalibres, 30);
      m.completarCalibres();
      expect(m.calibres[cal5060], 30);
      expect(m.faltaCalibres, 0);
    });

    test('Completar 100% no hace nada si los calibres ya se pasan', () {
      final m = MuestraBorrador(numero: 1, calibres: {cal4550: 70, cal5060: 40});
      m.completarCalibres();
      expect(m.calibres, {cal4550: 70, cal5060: 40});
    });

    test('la muestra nueva trae los calibres de la anterior, sin valores', () {
      final nueva = loteModelo().nuevaMuestra();
      expect(nueva.numero, 4);
      expect(nueva.calibres, {cal4550: 0, cal5060: 0});
      expect(nueva.calidad, isEmpty);
    });
  });
}
