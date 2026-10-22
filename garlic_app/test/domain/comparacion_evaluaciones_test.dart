import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/catalogo.dart';
import 'package:garlic_app/domain/models/evaluacion.dart';
import 'package:garlic_app/domain/models/formulario.dart';
import 'package:garlic_app/domain/use_cases/comparacion_evaluaciones.dart';
import 'package:garlic_app/ui/features/evaluacion/view_models/bandeja_view_model.dart';

const primera = 'c-primera';
const segunda = 'c-segunda';
const cal4550 = 'cal-45-50';
const cal5060 = 'cal-50-60';
const cerosa = 'd-cerosa';
const noContiene = 'd-no-contiene';
const fusarium = 'e-fusarium';

const formulario = FormularioEvaluacion(
  cultivoId: 'ajo',
  clasesCalidad: [
    CatalogoItem(id: primera, codigo: 'PRIMERA', nombre: 'PRIMERA', orden: 1),
    CatalogoItem(id: segunda, codigo: 'SEGUNDA', nombre: 'SEGUNDA', orden: 2),
  ],
  calibres: [
    CatalogoItem(id: cal4550, codigo: '45/50', nombre: '45/50', orden: 1),
    CatalogoItem(id: cal5060, codigo: '50/60', nombre: '50/60', orden: 2),
  ],
  tiposHumedad: [],
  tiposEmpaste: [],
  tiposDano: [
    CatalogoItem(id: cerosa, codigo: 'CEROSA', nombre: 'PARALISIS CEROSA'),
    CatalogoItem(id: noContiene, codigo: 'NO_CONTIENE', nombre: 'NO CONTIENE', esExcluyente: true),
  ],
  enfermedades: [CatalogoItem(id: fusarium, codigo: 'FUSARIUM', nombre: 'FUSARIUM', evaluarEnCampo: true)],
);

EvaluacionBorrador evaluacion(
  String id,
  List<double> primeras, {
  Map<String, double> calibres = const {},
  Set<String> danos = const {},
  Map<String, SanidadBorrador> sanidad = const {},
}) => EvaluacionBorrador(
  id: id,
  loteId: 'l-$id',
  fecha: DateTime(2025, 10, 10),
  estado: EstadoEvaluacion.cerrada,
  muestras: [
    for (final (i, p) in primeras.indexed)
      MuestraBorrador(numero: i + 1, calidad: {primera: p, segunda: 100 - p}, calibres: {...calibres}),
  ],
  danos: {...danos},
  sanidad: {...sanidad},
);

void main() {
  test('gana más % de primera y más valor por kg con los mismos precios base (ejemplo del Excel)', () {
    // A: 80/85/75 → precios 3.00/3.10/2.90, promedio 3.00, técnico 2.70 con llenado 0.30
    final a = evaluacion('a', [80, 85, 75]);
    final b = evaluacion('b', [70, 70, 70]);
    final c = ComparacionEvaluaciones.de(
      a,
      b,
      formulario,
      preciosBase: {primera: 3.4, segunda: 1.4},
      gastoLlenado: 0.30,
    );

    final filaPrimera = c.calidad.firstWhere((f) => f.id == primera);
    expect(filaPrimera.a, 80);
    expect(filaPrimera.b, 70);
    expect(filaPrimera.ganador, Ganador.a);
    // la segunda clase no tiene dirección
    expect(c.calidad.firstWhere((f) => f.id == segunda).ganador, isNull);

    expect(c.fijacionA.precioTecnico, 2.70);
    expect(c.fijacionB.precioTecnico, 2.50);
    expect(c.valorKg.ganador, Ganador.a);
    expect(c.valorKg.diferencia, -0.2);
  });

  test('sin precios base no hay valor por kg ni ganador en esa fila', () {
    final c = ComparacionEvaluaciones.de(evaluacion('a', [80]), evaluacion('b', [70]), formulario);
    expect(c.valorKg.a, isNull);
    expect(c.valorKg.ganador, isNull);
  });

  test('sanidad y daños: gana el menor; "NO CONTIENE" (excluyente) no cuenta como daño', () {
    final a = evaluacion(
      'a',
      [80],
      danos: {cerosa},
      sanidad: {fusarium: SanidadBorrador(presente: true, porcentaje: 5)},
    );
    final b = evaluacion('b', [80], danos: {noContiene}, sanidad: {fusarium: SanidadBorrador(presente: false)});
    final c = ComparacionEvaluaciones.de(a, b, formulario);
    FilaComparacion fila(String id) => c.sanidadYDanos.firstWhere((f) => f.id == id);

    expect(fila('enfermedades').ganador, Ganador.b);
    expect(fila('incidencia').a, 5);
    expect(fila('incidencia').ganador, Ganador.b);
    expect(fila('danos').b, 0);
    expect(fila('danos').ganador, Ganador.b);
    // primera empata (80 vs 80)
    expect(c.ganadas(Ganador.b), 3);
    expect(c.ganadas(Ganador.empate), 1);
  });

  test('empate cuando la diferencia de % es de hasta medio punto', () {
    final c = ComparacionEvaluaciones.de(evaluacion('a', [80]), evaluacion('b', [80.4]), formulario);
    expect(c.calidad.first.ganador, Ganador.empate);
  });

  test('calibres: unión de los usados por ambas, en el orden del catálogo', () {
    final a = evaluacion('a', [80], calibres: {cal5060: 100});
    final b = evaluacion('b', [80], calibres: {cal4550: 60, cal5060: 40});
    final c = ComparacionEvaluaciones.de(a, b, formulario);

    expect(c.calibres.map((f) => f.etiqueta), ['45/50', '50/60']);
    expect(c.calibres.first.a, 0);
    expect(c.calibres.first.b, 60);
    expect(c.calibres.every((f) => f.ganador == null), isTrue);
  });

  test('selección en la bandeja: máximo 2, una tercera reemplaza a la más antigua', () {
    var sel = BandejaViewModel.alternar(const [], 'e1');
    sel = BandejaViewModel.alternar(sel, 'e2');
    expect(sel, ['e1', 'e2']);
    sel = BandejaViewModel.alternar(sel, 'e3');
    expect(sel, ['e2', 'e3']);
    sel = BandejaViewModel.alternar(sel, 'e2');
    expect(sel, ['e3']);
  });
}
