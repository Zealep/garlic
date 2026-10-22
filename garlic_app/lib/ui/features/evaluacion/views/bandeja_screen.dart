import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/evaluacion.dart';
import '../../../../routing/rutas.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
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
          ListenableBuilder(
            listenable: viewModel,
            builder:
                (context, _) => TextButton.icon(
                  onPressed: viewModel.alternarComparar,
                  icon: Icon(viewModel.comparando ? PhosphorIconsBold.x : PhosphorIconsBold.scales),
                  label: Text(viewModel.comparando ? 'Cancelar' : 'Comparar'),
                ),
          ),
          if (ancho.esCompacto) const Padding(padding: EdgeInsets.only(right: 12), child: SyncChip(compacto: true)),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final vm = viewModel;
          if (vm.comparando) {
            final listo = vm.seleccion.length == 2;
            return FloatingActionButton.extended(
              onPressed:
                  listo
                      ? () async {
                        final (a, b) = (vm.seleccion[0], vm.seleccion[1]);
                        vm.alternarComparar();
                        await context.push(Rutas.comparar(a, b));
                      }
                      : null,
              backgroundColor: listo ? null : GColores.superficieAlt,
              foregroundColor: listo ? null : GColores.tintaSuave,
              icon: const Icon(PhosphorIconsBold.scales),
              label: Text('Comparar (${vm.seleccion.length}/2)'),
            );
          }
          return FloatingActionButton.extended(
            onPressed: () async {
              final lote = await seleccionarLote(context, vm.lotes_);
              if (lote != null && context.mounted) await context.push(Rutas.evaluar(lote.id));
            },
            icon: const Icon(PhosphorIconsBold.plus),
            label: const Text('Nueva evaluación'),
          );
        },
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
                if (viewModel.comparando)
                  const SliverToBoxAdapter(
                    child: AnchoMaximo(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(GEspacio.l, 0, GEspacio.l, GEspacio.m),
                        child: Aviso(mensaje: 'Marca 2 evaluaciones cerradas para compararlas.'),
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
                      itemBuilder: (context, i) {
                        final e = lista[i];
                        if (!viewModel.comparando) {
                          return EvaluacionTile(
                            evaluacion: e,
                            onTap: () => context.push(Rutas.evaluacion(e.loteId, e.id)),
                          );
                        }
                        return Opacity(
                          opacity: e.estado == EstadoEvaluacion.cerrada ? 1 : .45,
                          child: EvaluacionTile(
                            evaluacion: e,
                            seleccionada: viewModel.seleccion.contains(e.id),
                            onTap: () {
                              if (viewModel.seleccionar(e)) return;
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(content: Text('Solo se comparan evaluaciones cerradas')));
                            },
                          ),
                        );
                      },
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
