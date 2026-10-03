import '../models/catalogo.dart';
import '../models/compra.dart';

/// Validaciones del punto 3 (espejo de las del backend) para avisar antes de guardar, sin conexión.
/// Devuelven el mensaje del primer problema o null si está bien.
abstract final class ReglasCompra {
  /// Para pactar, cada clase de calidad presente en alguna muestra debe tener precio base.
  static String? fijacion(FijacionPrecio f, List<Map<String, double>> calidadMuestras, List<CatalogoItem> clases) {
    if (f.gastoLlenado < 0) return 'El gasto de llenado no puede ser negativo';
    if (f.preciosBase.values.any((p) => p < 0)) return 'Los precios base no pueden ser negativos';
    if (f.precioPactado != null) {
      if (f.precioPactado! <= 0) return 'El precio pactado debe ser mayor a 0';
      final faltan = <String>{
        for (final m in calidadMuestras)
          for (final e in m.entries)
            if (e.value > 0 && !f.preciosBase.containsKey(e.key)) e.key,
      };
      if (faltan.isNotEmpty) {
        final nombres = clases.where((c) => faltan.contains(c.id)).map((c) => c.etiqueta).join(', ');
        return 'Para pactar falta el precio base de: $nombres';
      }
    }
    return null;
  }

  static String? carga(Carga c) {
    if (c.kg <= 0) return 'Ingrese los kg cargados';
    if (c.precioKg <= 0) return 'Ingrese el precio por kg';
    if (c.destarePct < 0 || c.destarePct > 100) return 'El destare debe estar entre 0 y 100%';
    if (c.cantidadEmpaques < 0) return 'La cantidad de empaques no puede ser negativa';
    return null;
  }

  static String? gasto(GastoVinculado g, CatalogoItem? tipo) {
    if (tipo == null) return 'Elija el tipo de gasto';
    if (g.monto <= 0) return 'Ingrese el monto';
    if (tipo.requiereDescripcion && (g.descripcion ?? '').trim().isEmpty) return 'Describa el gasto (${tipo.etiqueta})';
    return null;
  }

  static String? pago(Pago p) {
    if (p.condicionPagoId.isEmpty) return 'Elija la condición del pago';
    if (p.monto <= 0) return 'Ingrese el monto';
    return null;
  }
}
