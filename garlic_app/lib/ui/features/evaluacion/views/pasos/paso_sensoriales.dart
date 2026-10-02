import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/evaluacion.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/evaluacion_view_model.dart';
import '../widgets/galeria_fotos.dart';

/// Paso 3: factores sensoriales (humedad, empaste, daños no visibles).
class PasoSensoriales extends StatelessWidget {
  const PasoSensoriales({super.key, required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    final b = vm.borrador!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeccionTarjeta(
          titulo: '2.2.1 Humedad',
          icono: PhosphorIconsBold.drop,
          child: Column(
            children: [
              for (final tipo in f.tiposHumedad) ...[
                _FilaHumedad(
                  etiqueta: tipo.etiqueta,
                  nivel: b.humedad[tipo.id],
                  onChanged: (n) => vm.setHumedad(tipo.id, n),
                ),
                if (tipo != f.tiposHumedad.last) const Divider(height: GEspacio.xl),
              ],
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: '2.2.2 Empaste',
          icono: PhosphorIconsBold.stack,
          child: Wrap(
            spacing: GEspacio.s,
            runSpacing: GEspacio.s,
            children: [
              for (final e in f.tiposEmpaste)
                FilterChip(
                  label: Text(e.etiqueta),
                  selected: b.empastes.contains(e.id),
                  onSelected: (_) => vm.alternarEmpaste(e.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Daños no visibles',
          icono: PhosphorIconsBold.bug,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: GEspacio.s,
                runSpacing: GEspacio.s,
                children: [
                  for (final d in f.tiposDano)
                    FilterChip(
                      label: Text(d.etiqueta),
                      selected: b.danos.contains(d.id),
                      selectedColor: d.esExcluyente ? GColores.secundarioSuave : GColores.errorSuave,
                      checkmarkColor: d.esExcluyente ? GColores.secundario : GColores.error,
                      onSelected: (_) => vm.alternarDano(d),
                    ),
                ],
              ),
              const SizedBox(height: GEspacio.s),
              Text('"No contiene" desmarca los demás daños.', style: t.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        GaleriaFotos(
          titulo: 'Fotos sensoriales',
          ayuda: 'Evidencia de humedad, empaste o daños (ej. gotas dentro, diente morado, parálisis).',
          fotos: vm.fotosDe(SeccionFoto.sensoriales),
          editable: vm.editable,
          onAgregar: (bytes, mime) => vm.agregarFoto(bytes, mime, seccion: SeccionFoto.sensoriales),
          onEliminar: vm.eliminarFoto,
        ),
      ],
    );
  }
}

class _FilaHumedad extends StatelessWidget {
  const _FilaHumedad({required this.etiqueta, required this.nivel, required this.onChanged});

  final String etiqueta;
  final NivelHumedad? nivel;
  final ValueChanged<NivelHumedad?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final selector = SegmentedButton<NivelHumedad?>(
      showSelectedIcon: false,
      emptySelectionAllowed: true,
      segments: [for (final n in NivelHumedad.values) ButtonSegment(value: n, label: Text(n.etiqueta))],
      selected: {nivel},
      onSelectionChanged:
          (s) => onChanged(
            s.isEmpty
                ? null
                : s.first == nivel
                ? null
                : s.first,
          ),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) && nivel != null ? GColores.humedadSuave(nivel!) : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) && nivel != null ? GColores.humedad(nivel!) : GColores.tintaSuave,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final titulo = Row(
          children: [
            Expanded(child: Text(etiqueta, style: t.titleSmall)),
            if (nivel == null) Text('No observado', style: t.bodySmall),
          ],
        );
        if (c.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titulo, const SizedBox(height: GEspacio.s), selector],
          );
        }
        return Row(children: [Expanded(child: titulo), const SizedBox(width: GEspacio.m), selector]);
      },
    );
  }
}
