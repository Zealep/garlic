import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/compra.dart';
import '../../../../../domain/models/foto.dart';
import '../../../../../domain/models/sync.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/galeria_fotos.dart';
import '../../view_models/compra_view_model.dart';

/// Abre un formulario de la compra en una hoja inferior (celular) con ancho máximo en pantallas grandes.
Future<void> abrirFormularioCompra(BuildContext context, Widget formulario) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder:
      (context) =>
          Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: formulario),
);

/// Estructura común: título, campos, error, fotos y botones Guardar / Eliminar.
class MarcoFormulario extends StatelessWidget {
  const MarcoFormulario({
    super.key,
    required this.titulo,
    required this.children,
    required this.onGuardar,
    this.error,
    this.onEliminar,
    this.guardando = false,
  });

  final String titulo;
  final List<Widget> children;
  final VoidCallback? onGuardar;
  final VoidCallback? onEliminar;
  final String? error;
  final bool guardando;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(GEspacio.xl, 0, GEspacio.xl, GEspacio.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: t.titleLarge),
          const SizedBox(height: GEspacio.l),
          for (final c in children) ...[c, const SizedBox(height: GEspacio.m)],
          if (error != null) ...[
            Text(error!, style: t.bodyMedium!.copyWith(color: GColores.error, fontWeight: FontWeight.w600)),
            const SizedBox(height: GEspacio.m),
          ],
          Row(
            children: [
              if (onEliminar != null)
                TextButton.icon(
                  onPressed: onEliminar,
                  style: TextButton.styleFrom(foregroundColor: GColores.error),
                  icon: const Icon(PhosphorIconsBold.trash),
                  label: const Text('Eliminar'),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: guardando ? null : onGuardar,
                icon: const Icon(PhosphorIconsBold.floppyDisk),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fotos de un registro en un formulario: las ya guardadas y las nuevas, que se guardan
/// después del registro (así se suben en orden).
class FotosFormulario extends StatefulWidget {
  const FotosFormulario({
    super.key,
    required this.vm,
    required this.entidad,
    required this.entidadId,
    required this.controlador,
    required this.editable,
  });

  final CompraViewModel vm;
  final EntidadComprobante entidad;
  final String entidadId;
  final FotosNuevas controlador;
  final bool editable;

  @override
  State<FotosFormulario> createState() => _FotosFormularioState();
}

class _FotosFormularioState extends State<FotosFormulario> {
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: widget.vm, builder: (context, _) => _galeria());

  Widget _galeria() {
    final guardadas = widget.vm.fotosDe(widget.entidadId);
    return GaleriaFotos(
      titulo: widget.entidad.etiqueta,
      ayuda: 'Opcional: foto de respaldo.',
      fotos: [...guardadas, ...widget.controlador.fotos],
      editable: widget.editable,
      onAgregar: (bytes, mime) async => setState(() => widget.controlador.agregar(bytes, mime)),
      onEliminar: (id) async {
        if (widget.controlador.quitar(id)) {
          setState(() {});
        } else {
          await widget.vm.eliminarFoto(id);
          setState(() {});
        }
      },
    );
  }
}

/// Fotos tomadas en el formulario que aún no se guardan.
class FotosNuevas {
  final List<FotoNueva> fotos = [];
  var _n = 0;

  void agregar(Uint8List bytes, String mime) => fotos.add(FotoNueva('nueva-${_n++}', bytes, mime));

  bool quitar(String id) {
    final antes = fotos.length;
    fotos.removeWhere((f) => f.id == id);
    return fotos.length != antes;
  }

  /// Guarda las fotos asociadas al registro (después de guardar el registro).
  Future<void> guardar(CompraViewModel vm, EntidadComprobante entidad, String entidadId) async {
    for (final f in fotos) {
      await vm.agregarFoto(entidad, entidadId, f.bytes, f.mime);
    }
    fotos.clear();
  }
}

/// Foto tomada en el formulario que aún no se guarda en el equipo.
class FotoNueva implements FotoLocal {
  FotoNueva(this.id, this.bytes, this.mime);

  @override
  final String id;
  @override
  final Uint8List bytes;
  final String mime;

  @override
  SyncState get syncState => SyncState.pendiente;
}

/// Confirma una eliminación.
Future<bool> confirmarEliminar(BuildContext context, String que) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('¿Eliminar $que?'),
            content: const Text('Se quitará también del servidor al sincronizar.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: GColores.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    ) ??
    false;
