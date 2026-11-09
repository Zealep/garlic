import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/catalogos_repository.dart';
import '../data/repositories/compra_repository.dart';
import '../data/repositories/config_repository.dart';
import '../data/repositories/evaluaciones_repository.dart';
import '../data/repositories/lotes_repository.dart';
import '../data/repositories/sesion_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/repositories/usuarios_repository.dart';
import '../ui/core/layout/shell_adaptativo.dart';
import '../ui/features/acceso/view_models/acceso_view_model.dart';
import '../ui/features/acceso/view_models/cambiar_clave_view_model.dart';
import '../ui/features/acceso/views/acceso_screen.dart';
import '../ui/features/acceso/views/cambiar_clave_screen.dart';
import '../ui/features/catalogos/view_models/catalogos_view_model.dart';
import '../ui/features/catalogos/views/catalogos_screen.dart';
import '../ui/features/comparacion/view_models/comparacion_view_model.dart';
import '../ui/features/comparacion/views/comparacion_screen.dart';
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
import '../ui/features/sync/views/sync_screen.dart';
import '../ui/features/usuarios/view_models/usuarios_view_model.dart';
import '../ui/features/usuarios/views/usuarios_screen.dart';
import 'rutas.dart';

final _raiz = GlobalKey<NavigatorState>();

/// Navegación. Las pantallas de trabajo intenso (formulario de lote, wizard) se abren a pantalla
/// completa sobre la navegación principal para concentrar al evaluador en la tarea.
///
/// Acceso: sin sesión (o vencida) todo lleva a [Rutas.acceso]; con contraseña temporal, a [Rutas.clave].
GoRouter crearRouter(ConfigRepository config, SesionRepository sesion) => GoRouter(
  navigatorKey: _raiz,
  initialLocation: Rutas.inicio,
  refreshListenable: Listenable.merge([config, sesion]),
  redirect: (context, state) => redireccionAcceso(
    ubicacion: state.matchedLocation,
    autenticado: sesion.autenticado && config.configurado,
    debeCambiarClave: sesion.debeCambiarClave,
  ),
  routes: [
    GoRoute(
      path: Rutas.acceso,
      builder:
          (context, _) => _ConViewModel(
            crear:
                (c) => AccesoViewModel(
                  sesion: c.read<SesionRepository>(),
                  config: c.read<ConfigRepository>(),
                  catalogos: c.read<CatalogosRepository>(),
                  lotes: c.read<LotesRepository>(),
                  evaluaciones: c.read<EvaluacionesRepository>(),
                  sync: c.read<SyncRepository>(),
                ),
            builder: (vm) => AccesoScreen(viewModel: vm),
          ),
    ),
    GoRoute(
      path: Rutas.clave,
      parentNavigatorKey: _raiz,
      builder:
          (context, _) => _ConViewModel(
            crear: (c) => CambiarClaveViewModel(sesion: c.read<SesionRepository>()),
            builder: (vm) => CambiarClaveScreen(viewModel: vm),
          ),
    ),
    GoRoute(
      path: Rutas.usuarios,
      parentNavigatorKey: _raiz,
      builder:
          (context, _) => _ConViewModel(
            crear:
                (c) => UsuariosViewModel(usuarios: c.read<UsuariosRepository>(), sesion: c.read<SesionRepository>()),
            builder: (vm) => UsuariosScreen(viewModel: vm),
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
                          compra: c.read<CompraRepository>(),
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
                    crear:
                        (c) => LotesViewModel(
                          lotes: c.read<LotesRepository>(),
                          evaluaciones: c.read<EvaluacionesRepository>(),
                        ),
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
              routes: [
                GoRoute(
                  path: 'comparar',
                  parentNavigatorKey: _raiz,
                  builder: (context, state) {
                    final q = state.uri.queryParameters;
                    final (a, b) = (q['a'] ?? '', q['b'] ?? '');
                    return _ConViewModel(
                      key: ValueKey('comparar-$a-$b'),
                      crear:
                          (c) => ComparacionViewModel(
                            idA: a,
                            idB: b,
                            evaluaciones: c.read<EvaluacionesRepository>(),
                            lotes: c.read<LotesRepository>(),
                            catalogos: c.read<CatalogosRepository>(),
                            compra: c.read<CompraRepository>(),
                          ),
                      builder: (vm) => ComparacionScreen(viewModel: vm),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(routes: [GoRoute(path: Rutas.sync, builder: (context, _) => const SyncScreen())]),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Rutas.catalogos,
              builder:
                  (context, _) => _ConViewModel(
                    crear:
                        (c) => CatalogosViewModel(
                          catalogos: c.read<CatalogosRepository>(),
                          config: c.read<ConfigRepository>(),
                        ),
                    builder: (vm) => CatalogosScreen(viewModel: vm),
                  ),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Regla de navegación del acceso (pura, para testearla).
String? redireccionAcceso({required String ubicacion, required bool autenticado, required bool debeCambiarClave}) {
  final enAcceso = ubicacion == Rutas.acceso;
  if (!autenticado) return enAcceso ? null : Rutas.acceso;
  if (debeCambiarClave) return ubicacion == Rutas.clave ? null : Rutas.clave;
  if (enAcceso) return Rutas.inicio;
  return null;
}

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
