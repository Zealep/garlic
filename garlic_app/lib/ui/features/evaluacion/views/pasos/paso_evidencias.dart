import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/evaluacion.dart';
import '../../../../../domain/models/sync.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/evaluacion_view_model.dart';

/// Paso 5: evidencias fotográficas por muestra y generales. Se guardan en el equipo y
/// se suben solas cuando hay conexión.
class PasoEvidencias extends StatelessWidget {
  const PasoEvidencias({super.key, required this.vm});

  final EvaluacionViewModel vm;

  Future<void> _tomar(BuildContext context, ImageSource fuente, int? muestra) async {
    final foto = await ImagePicker().pickImage(source: fuente, maxWidth: 1600, imageQuality: 72);
    if (foto == null) return;
    final bytes = await foto.readAsBytes();
    final mime = foto.mimeType ?? (foto.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
    await vm.agregarFoto(bytes, mime, muestraNumero: muestra);
  }

  @override
  Widget build(BuildContext context) {
    final grupos = <int?>[...vm.borrador!.muestras.map((m) => m.numero), null];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Aviso(mensaje: 'Las fotos se comprimen y guardan en el equipo; se suben al sincronizar.'),
        const SizedBox(height: GEspacio.l),
        for (final numero in grupos) ...[
          _GrupoFotos(
            titulo: numero == null ? 'Evidencias generales' : 'Muestra $numero',
            fotos: vm.fotos.where((f) => f.muestraNumero == numero).toList(),
            editable: vm.editable,
            onCamara: () => _tomar(context, ImageSource.camera, numero),
            onGaleria: () => _tomar(context, ImageSource.gallery, numero),
            onEliminar: vm.eliminarFoto,
          ),
          const SizedBox(height: GEspacio.l),
        ],
      ],
    );
  }
}

class _GrupoFotos extends StatelessWidget {
  const _GrupoFotos({
    required this.titulo,
    required this.fotos,
    required this.editable,
    required this.onCamara,
    required this.onGaleria,
    required this.onEliminar,
  });

  final String titulo;
  final List<EvidenciaLocal> fotos;
  final bool editable;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final Future<void> Function(String) onEliminar;

  @override
  Widget build(BuildContext context) {
    return SeccionTarjeta(
      titulo: titulo,
      icono: PhosphorIconsBold.camera,
      accion: Pastilla(texto: '${fotos.length}', color: GColores.primario),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fotos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                mainAxisSpacing: GEspacio.s,
                crossAxisSpacing: GEspacio.s,
              ),
              itemCount: fotos.length,
              itemBuilder: (context, i) => _Miniatura(foto: fotos[i], editable: editable, onEliminar: onEliminar),
            ),
            const SizedBox(height: GEspacio.m),
          ],
          if (editable)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamara,
                    icon: const Icon(PhosphorIconsBold.camera),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: GEspacio.m),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGaleria,
                    icon: const Icon(PhosphorIconsBold.images),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.foto, required this.editable, required this.onEliminar});

  final EvidenciaLocal foto;
  final bool editable;
  final Future<void> Function(String) onEliminar;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GRadio.chico),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(foto.bytes, fit: BoxFit.cover, gaplessPlayback: true, semanticLabel: 'Evidencia fotográfica'),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: EstadoSync(estado: foto.syncState, compacto: true),
            ),
          ),
          if (editable && foto.syncState != SyncState.sincronizado)
            Positioned(
              right: 2,
              top: 2,
              child: IconButton.filledTonal(
                tooltip: 'Eliminar foto',
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .9)),
                icon: const Icon(PhosphorIconsBold.trash, size: 18, color: GColores.error),
                onPressed: () => onEliminar(foto.id),
              ),
            ),
        ],
      ),
    );
  }
}
