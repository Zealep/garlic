import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/use_cases/seguimiento_lotes.dart';
import '../theme/colores.dart';
import 'componentes.dart';

/// Pastilla de la fecha de corte: rojo si ya pasó, ámbar hoy/mañana, morado esta semana.
class PastillaCorte extends StatelessWidget {
  const PastillaCorte({super.key, required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    final color = switch (dias) {
      < 0 => GColores.error,
      0 || 1 => GColores.advertencia,
      <= 7 => GColores.primario,
      _ => GColores.tintaSuave,
    };
    return Pastilla(texto: SeguimientoLotes.textoCorte(dias), color: color, icono: PhosphorIconsBold.scissors);
  }
}
