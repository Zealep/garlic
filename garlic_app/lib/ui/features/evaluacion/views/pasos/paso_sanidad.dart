import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campo_porcentaje.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/evaluacion_view_model.dart';

/// Paso 4: sanidad (Raíz rosada, Fusarium y demás enfermedades a evaluar en campo): SI/NO + %.
class PasoSanidad extends StatelessWidget {
  const PasoSanidad({super.key, required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    if (f.enfermedades.isEmpty) {
      return const EstadoVacio(
        titulo: 'Sin enfermedades configuradas',
        mensaje: 'La empresa no marcó enfermedades para evaluar en campo.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in f.enfermedades) ...[
          Builder(
            builder: (context) {
              final s = vm.borrador!.sanidad[e.id];
              final presente = s?.presente;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(GEspacio.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: presente == true ? GColores.errorSuave : GColores.superficieAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              PhosphorIconsBold.virus,
                              size: 20,
                              color: presente == true ? GColores.error : GColores.tintaSuave,
                            ),
                          ),
                          const SizedBox(width: GEspacio.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.etiqueta, style: t.titleMedium),
                                if (e.nombreCientifico != null)
                                  Text(e.nombreCientifico!, style: t.bodySmall!.copyWith(fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            emptySelectionAllowed: true,
                            segments: const [
                              ButtonSegment(value: false, label: Text('NO')),
                              ButtonSegment(value: true, label: Text('SÍ')),
                            ],
                            selected: {if (presente != null) presente},
                            onSelectionChanged: (sel) {
                              if (sel.isNotEmpty) vm.setPresente(e.id, sel.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((st) {
                                if (!st.contains(WidgetState.selected)) return null;
                                return presente == true ? GColores.errorSuave : GColores.secundarioSuave;
                              }),
                              foregroundColor: WidgetStateProperty.resolveWith((st) {
                                if (!st.contains(WidgetState.selected)) return GColores.tintaSuave;
                                return presente == true ? GColores.error : GColores.secundario;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (presente == null) ...[
                        const SizedBox(height: GEspacio.s),
                        Text('Responda SÍ o NO', style: t.bodySmall!.copyWith(color: GColores.advertencia)),
                      ],
                      if (presente == true) ...[
                        const SizedBox(height: GEspacio.l),
                        CampoPorcentaje(
                          etiqueta: '¿Qué porcentaje tiene?',
                          valor: s?.porcentaje,
                          habilitado: vm.editable,
                          onChanged: (v) => vm.setPorcentajeEnfermedad(e.id, v),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: GEspacio.m),
        ],
      ],
    );
  }
}
