import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/domain/models/definicion_catalogo.dart';

DefinicionCatalogo def(String recurso) => DefinicionCatalogo.todas.firstWhere((d) => d.recurso == recurso);

void main() {
  test('cubre todos los catálogos del backend, sin repetir', () {
    final recursos = DefinicionCatalogo.todas.map((d) => d.recurso).toList();
    expect(recursos.toSet(), hasLength(recursos.length));
    expect(recursos, containsAll(['clases-calidad', 'calibres', 'tipos-empaque', 'tipos-gasto', 'condiciones-pago']));
  });

  test('una clase de calidad nueva (Poroto) se envía con el cultivo', () {
    final body = def('clases-calidad').request({'codigo': 'POROTO', 'nombre': 'POROTO', 'orden': 3}, 'ajo');
    expect(body, {'cultivoId': 'ajo', 'codigo': 'POROTO', 'nombre': 'POROTO', 'orden': 3});
  });

  test('las localidades no son por cultivo', () {
    final body = def('localidades').request({'nombre': 'EL PEDREGAL', 'tipo': 'CCPP'}, 'ajo');
    expect(body.containsKey('cultivoId'), isFalse);
    expect(body['tipo'], 'CCPP');
  });

  test('campos propios: peso del empaque y banderas del gasto', () {
    expect(def('tipos-empaque').campos.map((c) => c.clave), contains('pesoReferencialKg'));
    expect(def('tipos-gasto').campos.map((c) => c.clave), containsAll(['porCarga', 'requiereDescripcion']));
  });
}
