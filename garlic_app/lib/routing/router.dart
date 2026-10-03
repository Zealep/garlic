import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/catalogos_repository.dart';
import '../data/repositories/compra_repository.dart';
import '../data/repositories/config_repository.dart';
import '../data/repositories/evaluaciones_repository.dart';
import '../data/repositories/lotes_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../ui/core/layout/shell_adaptativo.dart';
import '../ui/features/compra/view_models/compra_view_model.dart';
import '../ui/features/compra/views/compra_screen.dart';
import '../ui/features/evaluacion/view_models/bandeja_view_model.dart';
import '../ui/features/evaluacion/view_models/evaluacion_view_model.dart';
import '../ui/features/evaluacion/views/bandeja_screen.dart';
import '../ui/features/evaluacion/views/evaluacion_screen.dart';
import '../ui/features/inicio/view_models/inicio_view_model.dart';
import '../ui/features/inicio/views/inicio_screen.dart';
import '../ui/features/lotes/view_models/lote_form_view_model.dart';
import '../ui/features/lotes/view_models/lotes_view_model.dart';
import '../ui/features/lotes/views/lote_detalle_screen.dart';
import '../ui/features/lotes/views/lote_form_screen.dart';
import '../ui/features/lotes/views/lotes_screen.dart';
import '../ui/features/setup/view_models/setup_view_model.dart';
import '../ui/features/setup/views/setup_screen.dart';
import '../ui/features/sync/views/sync_screen.dart';
import 'rutas.dart';

final _raiz = GlobalKey<NavigatorState>();

/// Navegación. Las pantallas de trabajo intenso (formulario de lote, wizard) se abren a pantalla
/// completa sobre la navegación principal para concentrar al evaluador en la tarea.
GoRouter crearRouter(ConfigRepository config) => GoRouter(
  navigatorKey: _raiz,
  initialLocation: Rutas.inicio,
  refreshListenable: config,
  redirect: (context, state) {
    final enSetup = state.matchedLocation == Rutas.setup;
    if (!config.configurado) return enSetup ? null : Rutas.setup;
    return null;
  },
  routes: [
    GoRoute(
      path: Rutas.setup,
      builder:
          (context, _) => _ConViewModel(
            crear:
                (c) => SetupViewModel(
                  config: c.read<ConfigRepository>(),
                  catalogos: c.read<CatalogosRepository>(),
                  lotes: c.read<LotesRepository>(),
                  evaluaciones: c.read<EvaluacionesRepository>(),
                ),
            builder: (vm) => SetupScreen(viewModel: vm),
          ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellAdaptativo(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Rutas.inicio,
              builder:
                  (context, _) => _ConViewModel(
                    crear:
                        (c) => InicioViewModel(
                          lotes: c.read<LotesRepository>(),
                          evaluaciones: c.read<EvaluacionesRepository>(),
                          sync: c.read<SyncRepository>(),
                          catalogos: c.read<CatalogosRepository>(),
                          config: c.read<ConfigRepository>(),
                        ),
                    builder: (vm) => InicioScreen(viewModel: vm),
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Rutas.lotes,
              builder:
                  (context, _) => _ConViewModel(
                    crear: (c) => LotesViewModel(lotes: c.read<LotesRepository>()),
                    builder: (vm) => LotesScreen(viewModel: vm),
                  ),
              routes: [
                GoRoute(
                  path: 'nuevo',
                  parentNavigatorKey: _raiz,
                  builder:
                      (context, _) => _ConViewModel(
                        crear:
                            (c) => LoteFormViewModel(
                              catalogos: c.read<CatalogosRepository>(),
                              lotes: c.read<LotesRepository>(),
                            ),
                        builder: (vm) => LoteFormScreen(viewModel: vm),
                      ),
                ),
                GoRoute(
                  path: ':loteId',
                  builder: (context, state) {
                    final id = state.pathParameters['loteId']!;
                    return _ConViewModel(
                      key: ValueKey(id),
                      crear:
                          (c) => LoteDetalleViewModel(
                            loteId: id,
                            lotes: c.read<LotesRepository>(),
                            evaluaciones: c.read<EvaluacionesRepository>(),
                            compra: c.read<CompraRepository>(),
                          ),
                      builder: (vm) => LoteDetalleScreen(viewModel: vm),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'evaluar',
                      parentNavigatorKey: _raiz,
                      builder: (context, state) => _wizard(state.pathParameters['loteId']!, null),
                    ),
                    GoRoute(
                      path: 'compra',
                      parentNavigatorKey: _raiz,
                      builder: (context, state) {
                        final id = state.pathParameters['loteId']!;
                        return _ConViewModel(
                          key: ValueKey('compra-$id'),
                          crear:
                              (c) => CompraViewModel(
                                loteId: id,
                                lotes: c.read<LotesRepository>(),
                                evaluaciones: c.read<EvaluacionesRepository>(),
                                compra: c.read<CompraRepository>(),
                                catalogos: c.read<CatalogosRepository>(),
                              ),
                          builder: (vm) => CompraScreen(viewModel: vm),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'evaluaciones/:evaluacionId',
                      parentNavigatorKey: _raiz,
                      builder:
                          (context, state) =>
                              _wizard(state.pathParameters['loteId']!, state.pathParameters['evaluacionId']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Rutas.evaluaciones,
              builder:
                  (context, _) => _ConViewModel(
                    crear:
                        (c) => BandejaViewModel(
                          evaluaciones: c.read<EvaluacionesRepository>(),
                          lotes: c.read<LotesRepository>(),
                        ),
                    builder: (vm) => BandejaScreen(viewModel: vm),
                  ),
            ),
          ],
        ),
        StatefulShellBranch(routes: [GoRoute(path: Rutas.sync, builder: (context, _) => const SyncScreen())]),
      ],
    ),
  ],
);

Widget _wizard(String loteId, String? evaluacionId) => _ConViewModel(
  key: ValueKey('$loteId/$evaluacionId'),
  crear:
      (c) => EvaluacionViewModel(
        loteId: loteId,
        evaluacionId: evaluacionId,
        lotes: c.read<LotesRepository>(),
        evaluaciones: c.read<EvaluacionesRepository>(),
        catalogos: c.read<CatalogosRepository>(),
        config: c.read<ConfigRepository>(),
      ),
  builder: (vm) => EvaluacionScreen(viewModel: vm),
);

/// Crea el ViewModel de la pantalla con sus repositorios (inyectados por Provider)
/// y lo libera al salir de la ruta.
class _ConViewModel<T extends ChangeNotifier> extends StatefulWidget {
  const _ConViewModel({super.key, required this.crear, required this.builder});

  final T Function(BuildContext) crear;
  final Widget Function(T) builder;

  @override
  State<_ConViewModel<T>> createState() => _ConViewModelState<T>();
}

class _ConViewModelState<T extends ChangeNotifier> extends State<_ConViewModel<T>> {
  late final T _vm = widget.crear(context);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_vm);
}
