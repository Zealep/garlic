import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/lote.dart';
import '../../../../routing/rutas.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/sync_chip.dart';
import '../view_models/lotes_view_model.dart';

class LotesScreen extends StatelessWidget {
  const LotesScreen({super.key, required this.viewModel});

  final LotesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ancho = AnchoVentana.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotes'),
        actions: [
          if (ancho.esCompacto) const Padding(padding: EdgeInsets.only(right: 12), child: SyncChip(compacto: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Rutas.loteNuevo),
        icon: const Icon(PhosphorIconsBold.plus),
        label: const Text('Nuevo lote'),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final lotes = viewModel.lotes;
          return RefreshIndicator(
            onRefresh: () => viewModel.refrescar.execute(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AnchoMaximo(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.s, GEspacio.l, GEspacio.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Buscar código, zona, agricultor o variedad',
                              prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                            ),
                            onChanged: viewModel.buscar,
                          ),
                          const SizedBox(height: GEspacio.m),
                          Row(
                            children: [
                              FilterChip(
                                label: const Text('Solo activos'),
                                selected: viewModel.soloActivos,
                                onSelected: viewModel.alternarActivos,
                              ),
                              const Spacer(),
                              Text('${lotes.length} de ${viewModel.total}', style: t.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (lotes.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EstadoVacio(
                      titulo: viewModel.total == 0 ? 'Sin lotes todavía' : 'Sin resultados',
                      mensaje:
                          viewModel.total == 0
                              ? 'Registra el primer lote con su zona, variedad y agricultor. Funciona sin conexión.'
                              : 'Prueba con otro texto de búsqueda.',
                    ),
                  )
                else
                  SliverAnchoMaximo(
                    // Lista en celular, grilla que se adapta en tablet/laptop (flutter-build-responsive-layout)
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 520,
                        mainAxisExtent: 158,
                        mainAxisSpacing: GEspacio.m,
                        crossAxisSpacing: GEspacio.m,
                      ),
                      itemCount: lotes.length,
                      itemBuilder: (context, i) => _LoteCard(lote: lotes[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoteCard extends StatelessWidget {
  const _LoteCard({required this.lote});

  final Lote lote;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Rutas.lote(lote.id)),
        child: Padding(
          padding: const EdgeInsets.all(GEspacio.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(lote.codigo, style: t.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  EstadoSync(estado: lote.syncState, compacto: true),
                  if (!lote.activo) ...[
                    const SizedBox(width: 6),
                    const Pastilla(texto: 'Anulado', color: GColores.error),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.mapPin, size: 16, color: GColores.tintaSuave),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Zona ${lote.zona} · ${lote.localidad.texto}',
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: GColores.secundarioSuave,
                    child: Text(
                      lote.agricultor.nombres.isEmpty ? '?' : lote.agricultor.nombres[0],
                      style: const TextStyle(fontWeight: FontWeight.w700, color: GColores.secundario),
                    ),
                  ),
                  const SizedBox(width: GEspacio.s),
                  Expanded(
                    child: Text(
                      lote.agricultor.nombres,
                      style: t.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Pastilla(texto: lote.variedad.texto, color: GColores.primario, icono: PhosphorIconsFill.leaf),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
