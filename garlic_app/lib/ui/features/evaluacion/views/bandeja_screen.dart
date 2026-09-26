import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/evaluacion.dart';
import '../../../../routing/rutas.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/evaluacion_tile.dart';
import '../../../core/widgets/selector_lote.dart';
import '../../../core/widgets/sync_chip.dart';
import '../view_models/bandeja_view_model.dart';

class BandejaScreen extends StatelessWidget {
  const BandejaScreen({super.key, required this.viewModel});

  final BandejaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ancho = AnchoVentana.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluaciones'),
        actions: [
          if (ancho.esCompacto) const Padding(padding: EdgeInsets.only(right: 12), child: SyncChip(compacto: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final lote = await seleccionarLote(context, viewModel.lotes_);
          if (lote != null && context.mounted) await context.push(Rutas.evaluar(lote.id));
        },
        icon: const Icon(PhosphorIconsBold.plus),
        label: const Text('Nueva evaluación'),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final lista = viewModel.evaluaciones;
          return RefreshIndicator(
            onRefresh: () => viewModel.refrescar.execute(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AnchoMaximo(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.s, GEspacio.l, GEspacio.m),
                      child: Wrap(
                        spacing: GEspacio.s,
                        children: [
                          for (final (texto, estado) in [
                            ('Todas', null),
                            ('Borradores', EstadoEvaluacion.borrador),
                            ('Cerradas', EstadoEvaluacion.cerrada),
                          ])
                            ChoiceChip(
                              label: Text('$texto · ${viewModel.cuenta(estado)}'),
                              selected: viewModel.filtro == estado,
                              onSelected: (_) => viewModel.filtrar(estado),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (lista.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EstadoVacio(
                      titulo: 'Nada por aquí',
                      mensaje: 'Las evaluaciones que hagas en campo aparecerán aquí, aunque no tengas conexión.',
                    ),
                  )
                else
                  SliverAnchoMaximo(
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 560,
                        mainAxisExtent: 112,
                        mainAxisSpacing: GEspacio.s,
                        crossAxisSpacing: GEspacio.m,
                      ),
                      itemCount: lista.length,
                      itemBuilder:
                          (context, i) => EvaluacionTile(
                            evaluacion: lista[i],
                            onTap: () => context.push(Rutas.evaluacion(lista[i].loteId, lista[i].id)),
                          ),
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
