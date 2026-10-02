import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/evaluacion.dart';
import '../../../../../domain/models/sync.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';

/// Bloque de fotos dentro de una sección del wizard (datos generales, cada muestra, sensoriales).
/// Las fotos se comprimen, se guardan en el equipo y se suben solas al sincronizar.
class GaleriaFotos extends StatelessWidget {
  const GaleriaFotos({
    super.key,
    required this.titulo,
    required this.fotos,
    required this.editable,
    required this.onAgregar,
    required this.onEliminar,
    this.ayuda,
  });

  final String titulo;
  final String? ayuda;
  final List<EvidenciaLocal> fotos;
  final bool editable;
  final Future<void> Function(Uint8List bytes, String mime) onAgregar;
  final Future<void> Function(String id) onEliminar;

  Future<void> _tomar(ImageSource fuente) async {
    final foto = await ImagePicker().pickImage(source: fuente, maxWidth: 1600, imageQuality: 72);
    if (foto == null) return;
    final bytes = await foto.readAsBytes();
    final mime = foto.mimeType ?? (foto.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
    await onAgregar(bytes, mime);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SeccionTarjeta(
      titulo: titulo,
      icono: PhosphorIconsBold.camera,
      accion: Pastilla(texto: fotos.length == 1 ? '1 foto' : '${fotos.length} fotos', color: GColores.primario),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ayuda != null && fotos.isEmpty) ...[Text(ayuda!, style: t.bodySmall), const SizedBox(height: GEspacio.m)],
          if (fotos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
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
                    onPressed: () => _tomar(ImageSource.camera),
                    icon: const Icon(PhosphorIconsBold.camera),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: GEspacio.m),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _tomar(ImageSource.gallery),
                    icon: const Icon(PhosphorIconsBold.images),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            )
          else if (fotos.isEmpty)
            Text('Sin fotos', style: t.bodySmall),
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
