import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/evaluacion.dart';
import '../theme/colores.dart';
import 'componentes.dart';

/// Color e ícono del dictamen (pendiente = ámbar).
(Color, IconData) estiloResultado(ResultadoEvaluacion? r) => switch (r) {
  ResultadoEvaluacion.aceptada => (GColores.exito, PhosphorIconsBold.sealCheck),
  ResultadoEvaluacion.rechazada => (GColores.error, PhosphorIconsBold.xCircle),
  ResultadoEvaluacion.sinAcuerdo => (GColores.advertencia, PhosphorIconsBold.handshake),
  null => (GColores.tintaSuave, PhosphorIconsBold.hourglassMedium),
};

/// Pastilla con el estado visible de una evaluación: borrador, cerrada (resultado pendiente) o su dictamen.
class PastillaEstadoEvaluacion extends StatelessWidget {
  const PastillaEstadoEvaluacion({super.key, required this.estado, required this.resultado});

  final EstadoEvaluacion estado;
  final ResultadoEvaluacion? resultado;

  @override
  Widget build(BuildContext context) {
    if (estado == EstadoEvaluacion.borrador) {
      return const Pastilla(texto: 'Borrador', color: GColores.advertencia, icono: PhosphorIconsBold.pencilSimpleLine);
    }
    final (color, icono) = estiloResultado(resultado);
    return Pastilla(texto: resultado?.etiqueta ?? 'Cerrada · pendiente', color: color, icono: icono);
  }
}
