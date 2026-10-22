import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/evaluacion.dart';
import '../../../utils/formato.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';
import 'componentes.dart';
import 'resultado_evaluacion.dart';

/// Fila de evaluación reutilizada en inicio, bandeja y detalle de lote.
class EvaluacionTile extends StatelessWidget {
  const EvaluacionTile({
    super.key,
    required this.evaluacion,
    required this.onTap,
    this.mostrarLote = true,
    this.seleccionada,
  });

  final EvaluacionResumen evaluacion;
  final VoidCallback onTap;
  final bool mostrarLote;

  /// Modo selección (comparar): no null muestra una casilla en lugar de la flecha.
  final bool? seleccionada;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = evaluacion;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape:
          seleccionada ?? false
              ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GRadio.tarjeta),
                side: const BorderSide(color: GColores.primario, width: 2),
              )
              : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GEspacio.m),
          child: Row(
            children: [
              _Fecha(fecha: e.fecha),
              const SizedBox(width: GEspacio.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mostrarLote
                          ? '${e.loteCodigo}${e.zona == null ? '' : ' · ${e.zona}'}'
                          : 'Evaluación ${Formato.fecha(e.fecha)}',
                      style: t.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ['${e.nroMuestras} muestras', if (e.evaluador != null) e.evaluador!].join(' · '),
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        PastillaEstadoEvaluacion(estado: e.estado, resultado: e.resultado),
                        if (e.promedioPrimera != null)
                          Pastilla(
                            texto: 'Primera ${Formato.porcentaje(e.promedioPrimera)}',
                            color: GColores.tinta,
                            fondo: GColores.acentoSuave,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              EstadoSync(estado: e.syncState, compacto: true),
              const SizedBox(width: 4),
              if (seleccionada case final sel?)
                Checkbox(value: sel, onChanged: (_) => onTap())
              else
                const Icon(PhosphorIconsBold.caretRight, size: 18, color: GColores.tintaSuave),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fecha extends StatelessWidget {
  const _Fecha({required this.fecha});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: GColores.superficieAlt, borderRadius: BorderRadius.circular(GRadio.chico)),
    child: Column(
      children: [
        Text('${fecha.day}', style: GTipo.cifra(20)),
        Text(
          DateFormat('MMM', 'es').format(fecha).toUpperCase().replaceAll('.', ''),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: GColores.tintaSuave,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}
