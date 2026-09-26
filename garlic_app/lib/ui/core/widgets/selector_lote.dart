import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/lote.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';

/// Hoja para elegir el lote a evaluar.
Future<Lote?> seleccionarLote(BuildContext context, List<Lote> lotes) => showModalBottomSheet<Lote>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: GColores.fondo,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => _SelectorLote(lotes: lotes),
);

class _SelectorLote extends StatefulWidget {
  const _SelectorLote({required this.lotes});

  final List<Lote> lotes;

  @override
  State<_SelectorLote> createState() => _SelectorLoteState();
}

class _SelectorLoteState extends State<_SelectorLote> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final q = _q.toLowerCase();
    final lista =
        widget.lotes
            .where((l) => l.activo)
            .where((l) => q.isEmpty || '${l.codigo} ${l.zona} ${l.agricultor.nombres}'.toLowerCase().contains(q))
            .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder:
          (context, scroll) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: GEspacio.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('¿Qué lote vas a evaluar?', style: t.titleLarge),
                const SizedBox(height: GEspacio.m),
                TextField(
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por código, zona o agricultor',
                    prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: GEspacio.m),
                Expanded(
                  child:
                      lista.isEmpty
                          ? Center(child: Text('No hay lotes activos que coincidan', style: t.bodyMedium))
                          : ListView.separated(
                            controller: scroll,
                            itemCount: lista.length,
                            separatorBuilder: (_, __) => const SizedBox(height: GEspacio.s),
                            itemBuilder: (context, i) {
                              final l = lista[i];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: const CircleAvatar(
                                    backgroundColor: GColores.primarioSuave,
                                    child: Icon(PhosphorIconsFill.plant, color: GColores.primario),
                                  ),
                                  title: Text('${l.codigo} · ${l.zona}', style: t.titleSmall),
                                  subtitle: Text('${l.variedad.texto} · ${l.agricultor.nombres}'),
                                  trailing: const Icon(PhosphorIconsBold.caretRight),
                                  onTap: () => Navigator.of(context).pop(l),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}
