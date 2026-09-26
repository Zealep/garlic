import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/evaluacion.dart';
import '../../../utils/formato.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';
import 'componentes.dart';

/// Fila de evaluación reutilizada en inicio, bandeja y detalle de lote.
class EvaluacionTile extends StatelessWidget {
  const EvaluacionTile({super.key, required this.evaluacion, required this.onTap, this.mostrarLote = true});

  final EvaluacionResumen evaluacion;
  final VoidCallback onTap;
  final bool mostrarLote;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = evaluacion;
    final cerrada = e.estado == EstadoEvaluacion.cerrada;
    return Card(
      clipBehavior: Clip.antiAlias,
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
                        Pastilla(
                          texto: cerrada ? 'Cerrada' : 'Borrador',
                          color: cerrada ? GColores.secundario : GColores.primario,
                          icono: cerrada ? PhosphorIconsBold.sealCheck : PhosphorIconsBold.pencilSimpleLine,
                        ),
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
