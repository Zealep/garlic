import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../domain/models/definicion_catalogo.dart';
import '../../../../utils/command.dart';
import '../../../../utils/result.dart';

/// Administración de catálogos de la empresa (clases de calidad, calibres, empaques, …).
/// Trabaja en línea contra el servidor; cada cambio actualiza la caché que usa la app sin conexión.
class CatalogosViewModel extends ChangeNotifier {
  CatalogosViewModel({required CatalogosRepository catalogos, required ConfigRepository config})
    : _catalogos = catalogos,
      _config = config {
    cargar = Command(_cargar);
  }

  final CatalogosRepository _catalogos;
  final ConfigRepository _config;

  late final Command<void> cargar;

  DefinicionCatalogo? seleccionado;
  List<Map<String, Object?>> items = const [];
  bool mostrarInactivos = false;
  String filtro = '';

  String get _cultivoId => _config.config!.cultivoId;

  List<Map<String, Object?>> get visibles {
    final q = filtro.trim().toLowerCase();
    return items.where((i) {
      if (!mostrarInactivos && i['activo'] == false) return false;
      if (q.isEmpty) return true;
      return '${i['codigo'] ?? ''} ${i['nombre'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  int get inactivos => items.where((i) => i['activo'] == false).length;

  void seleccionar(DefinicionCatalogo? d) {
    seleccionado = d;
    items = const [];
    filtro = '';
    notifyListeners();
    if (d != null) unawaited(cargar.execute());
  }

  void setFiltro(String v) {
    filtro = v;
    notifyListeners();
  }

  void alternarInactivos() {
    mostrarInactivos = !mostrarInactivos;
    notifyListeners();
  }

  Future<Result<void>> _cargar() async {
    final d = seleccionado;
    if (d == null) return const Result.ok(null);
    final r = await _catalogos.listarAdmin(d, _cultivoId);
    if (seleccionado != d) return const Result.ok(null); // cambió de catálogo mientras cargaba
    switch (r) {
      case Ok(:final value):
        items = value;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final failure):
        return Result.error(failure);
    }
  }

  /// Valores iniciales del formulario: los del registro o los predeterminados (orden siguiente, booleanos en no).
  Map<String, Object?> valoresIniciales(Map<String, Object?>? item) {
    final d = seleccionado!;
    if (item != null) return {for (final c in d.campos) c.clave: item[c.clave]};
    final ordenes = items.map((i) => (i['orden'] as num?)?.toInt() ?? 0);
    return {
      for (final c in d.campos)
        c.clave: switch (c.tipo) {
          TipoCampo.booleano => false,
          TipoCampo.opcion => c.opciones.keys.first,
          _ when c.clave == 'orden' => (ordenes.isEmpty ? 0 : ordenes.reduce((a, b) => a > b ? a : b)) + 1,
          _ => null,
        },
    };
  }

  /// Valida en el equipo; devuelve el primer problema o null.
  String? validar(Map<String, Object?> valores) {
    for (final c in seleccionado!.campos) {
      final v = valores[c.clave];
      if (c.requerido && (v == null || (v is String && v.trim().isEmpty))) return 'Ingrese ${c.etiqueta.toLowerCase()}';
      if (c.clave == 'ubigeo' && v is String && v.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(v)) {
        return 'El ubigeo debe tener 6 dígitos';
      }
    }
    final d = seleccionado!;
    if (d.recurso == 'calibres') {
      final min = valores['diametroMinMm'] as num?;
      final max = valores['diametroMaxMm'] as num?;
      if (min != null && max != null && max <= min) return 'El diámetro máximo debe ser mayor al mínimo';
    }
    if (d.recurso == 'campanias') {
      final ini = valores['fechaInicio'] as String?;
      final fin = valores['fechaFin'] as String?;
      if (ini != null && fin != null && fin.compareTo(ini) < 0) return 'La fecha de fin es anterior al inicio';
    }
    return null;
  }

  Future<Result<void>> guardar(Map<String, Object?> valores, {String? id}) async {
    final problema = validar(valores);
    if (problema != null) return Result.error(AppFailure(FailureKind.validacion, problema));
    final r = await _catalogos.guardarAdmin(seleccionado!, _cultivoId, valores, id: id);
    if (r is Ok<void>) await cargar.execute();
    return r;
  }

  Future<Result<void>> cambiarActivo(Map<String, Object?> item, {required bool activo}) async {
    final r = await _catalogos.cambiarActivoAdmin(seleccionado!, _cultivoId, item['id']! as String, activo: activo);
    if (r is Ok<void>) await cargar.execute();
    return r;
  }

  @override
  void dispose() {
    cargar.dispose();
    super.dispose();
  }
}
