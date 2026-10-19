import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/evaluacion.dart';
import 'package:garlic_app/domain/models/lote.dart';
import 'package:garlic_app/domain/use_cases/seguimiento_lotes.dart';

final hoy = DateTime(2026, 10, 19, 15, 30);

Lote lote(String id, {String? corte, String estado = 'ACTIVO'}) => Lote.fromJson({
  'id': id,
  'codigo': 'LOTE $id',
  'estado': estado,
  'campania': {'id': 'c', 'codigo': '2026'},
  'cultivoId': 'ajo',
  'variedad': {'id': 'v', 'nombre': 'NAPURI'},
  'agricultor': {'id': 'a', 'nombres': 'KEVIN'},
  'localidad': {'id': 'l', 'nombre': 'EL PEDREGAL'},
  'zona': 'Z$id',
  'tipoCompra': {'id': 't', 'nombre': 'PRIMERA'},
  'fechaCorte': corte,
});

EvaluacionResumen evaluacion(String id, String loteId, DateTime fecha, {ResultadoEvaluacion? resultado}) =>
    EvaluacionResumen(
      id: id,
      loteId: loteId,
      loteCodigo: 'LOTE',
      fecha: fecha,
      estado: EstadoEvaluacion.cerrada,
      nroMuestras: 3,
      resultado: resultado,
    );

void main() {
  group('Fecha de corte', () {
    test('cuenta días calendario (la hora no importa)', () {
      expect(SeguimientoLotes.diasParaCorte(lote('1', corte: '2026-10-19'), hoy), 0);
      expect(SeguimientoLotes.diasParaCorte(lote('1', corte: '2026-10-24'), hoy), 5);
      expect(SeguimientoLotes.diasParaCorte(lote('1', corte: '2026-10-17'), hoy), -2);
      expect(SeguimientoLotes.diasParaCorte(lote('1'), hoy), isNull);
    });

    test('textos', () {
      expect(SeguimientoLotes.textoCorte(0), 'Corte hoy');
      expect(SeguimientoLotes.textoCorte(1), 'Corte mañana');
      expect(SeguimientoLotes.textoCorte(5), 'Corte en 5 días');
      expect(SeguimientoLotes.textoCorte(-3), 'Corte hace 3 días');
    });

    test('próximos cortes: activos, de 7 días atrás a 14 adelante, el más urgente primero', () {
      final lotes = [
        lote('lejos', corte: '2026-11-20'),
        lote('en5', corte: '2026-10-24'),
        lote('atrasado', corte: '2026-10-15'),
        lote('muyAtrasado', corte: '2026-10-01'),
        lote('anulado', corte: '2026-10-20', estado: 'ANULADO'),
        lote('sinFecha'),
        lote('hoy', corte: '2026-10-19'),
      ];
      expect(SeguimientoLotes.proximosCortes(lotes, hoy).map((l) => l.id), ['atrasado', 'hoy', 'en5']);
    });
  });

  test('la última evaluación de cada lote es la más reciente', () {
    final ultima = SeguimientoLotes.ultimaPorLote([
      evaluacion('e1', 'L1', DateTime(2026, 10, 1), resultado: ResultadoEvaluacion.sinAcuerdo),
      evaluacion('e2', 'L1', DateTime(2026, 10, 10), resultado: ResultadoEvaluacion.aceptada),
      evaluacion('e3', 'L2', DateTime(2026, 10, 5)),
    ]);
    expect(ultima['L1']!.id, 'e2');
    expect(ultima['L2']!.resultado, isNull);
  });

  group('Resultado de la evaluación', () {
    test('se conserva en el resumen y en el borrador guardado en el equipo', () {
      final r = EvaluacionResumen.fromJson(
        evaluacion('e', 'L', DateTime(2026, 10, 1), resultado: ResultadoEvaluacion.rechazada).toJson(),
      );
      expect(r.resultado, ResultadoEvaluacion.rechazada);

      final b = EvaluacionBorrador.fromRequestJson({
        'id': 'e',
        'fechaEvaluacion': '2026-10-01',
        'estado': 'CERRADA',
        'resultado': 'SIN_ACUERDO',
        'motivoResultado': 'Pide 3.20',
      }, loteId: 'L');
      expect(b.resultado, ResultadoEvaluacion.sinAcuerdo);
      expect(b.motivoResultado, 'Pide 3.20');
      // el resultado no viaja en el contenido (tiene su propio endpoint)
      expect(b.toRequestJson().containsKey('resultado'), isFalse);
    });

    test('valor desconocido o ausente = pendiente', () {
      expect(ResultadoEvaluacion.parse(null), isNull);
      expect(ResultadoEvaluacion.parse('QUIZAS'), isNull);
    });
  });
}
