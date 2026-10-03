import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campos.dart';
import '../../../../core/widgets/componentes.dart';
import '../../../../../domain/models/evaluacion.dart';
import '../../view_models/evaluacion_view_model.dart';
import '../../../../core/widgets/galeria_fotos.dart';

/// Paso 1: datos generales (evaluador, fecha, observación).
class PasoGeneral extends StatelessWidget {
  const PasoGeneral({super.key, required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final b = vm.borrador!;
    final lote = vm.lote!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeccionTarjeta(
          titulo: 'Lote a evaluar',
          icono: PhosphorIconsBold.plant,
          child: Column(
            children: [
              DatoFila(etiqueta: 'Agricultor', valor: lote.agricultor.nombres),
              DatoFila(etiqueta: 'Localidad', valor: '${lote.localidad.texto} · zona ${lote.zona}'),
              DatoFila(etiqueta: 'Tipo de compra', valor: lote.tipoCompra.texto),
            ],
          ),
        ),
        const TituloGrupo('Datos de la evaluación', icono: PhosphorIconsBold.clipboardText),
        DropdownButtonFormField<String>(
          value: vm.evaluadores.any((e) => e.id == b.evaluadorId) ? b.evaluadorId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Evaluador',
            prefixIcon: const Icon(PhosphorIconsRegular.userCircle),
            errorText: b.evaluadorId == null ? 'Seleccione el evaluador' : null,
          ),
          items: [for (final e in vm.evaluadores) DropdownMenuItem(value: e.id, child: Text(e.nombreVisible))],
          onChanged: vm.setEvaluador,
        ),
        const SizedBox(height: GEspacio.l),
        CampoFecha(etiqueta: 'Fecha de evaluación', valor: b.fecha, onChanged: vm.setFecha),
        const SizedBox(height: GEspacio.l),
        TextFormField(
          initialValue: b.observacion,
          minLines: 3,
          maxLines: 6,
          maxLength: 4000,
          decoration: const InputDecoration(
            labelText: 'Observación',
            alignLabelWithHint: true,
            hintText: 'Ej. Se recomienda cargar en 3 días para bajar la humedad',
          ),
          onChanged: vm.setObservacion,
        ),
        const SizedBox(height: GEspacio.s),
        const Aviso(
          mensaje:
              'Se toma una muestra representativa de acuerdo al campo. Todo se guarda en el equipo mientras avanzas.',
        ),
        const SizedBox(height: GEspacio.l),
        GaleriaFotos(
          titulo: 'Evidencias generales (opcional)',
          ayuda: 'Fotos del campo, del lote o de la carga.',
          fotos: vm.fotosDe(SeccionFoto.general),
          editable: vm.editable,
          onAgregar: (bytes, mime) => vm.agregarFoto(bytes, mime, seccion: SeccionFoto.general),
          onEliminar: vm.eliminarFoto,
        ),
      ],
    );
  }
}
