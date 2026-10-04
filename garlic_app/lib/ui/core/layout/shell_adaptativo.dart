import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/config_repository.dart';
import '../../../data/repositories/sync_repository.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';
import '../widgets/marca.dart';
import '../widgets/sync_chip.dart';
import 'breakpoints.dart';

class _Destino {
  const _Destino(this.etiqueta, this.icono, this.iconoActivo);

  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
}

const _destinos = [
  _Destino('Inicio', PhosphorIconsRegular.house, PhosphorIconsFill.house),
  _Destino('Lotes', PhosphorIconsRegular.plant, PhosphorIconsFill.plant),
  _Destino('Evaluaciones', PhosphorIconsRegular.clipboardText, PhosphorIconsFill.clipboardText),
  _Destino('Sincronizar', PhosphorIconsRegular.arrowsClockwise, PhosphorIconsBold.arrowsClockwise),
  _Destino('Catálogos', PhosphorIconsRegular.listChecks, PhosphorIconsFill.listChecks),
];

/// Estructura principal: barra inferior (compacto), riel (medio) o sidebar (expandido).
class ShellAdaptativo extends StatelessWidget {
  const ShellAdaptativo({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _ir(int i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = AnchoVentana.de(constraints.maxWidth);
        if (ancho.esCompacto) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _ir,
              destinations: [
                for (final (i, d) in _destinos.indexed)
                  NavigationDestination(
                    icon: i == 3 ? _IconoSync(icono: d.icono) : Icon(d.icono),
                    selectedIcon: Icon(d.iconoActivo, color: GColores.primario),
                    label: d.etiqueta,
                  ),
              ],
            ),
          );
        }
        final extendido = ancho.esExpandido;
        return Scaffold(
          body: Row(
            children: [
              _Lateral(extendido: extendido, indice: navigationShell.currentIndex, onSelect: _ir),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        );
      },
    );
  }
}

class _Lateral extends StatelessWidget {
  const _Lateral({required this.extendido, required this.indice, required this.onSelect});

  final bool extendido;
  final int indice;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigRepository>().config;
    return NavigationRail(
      extended: extendido,
      minExtendedWidth: 248,
      selectedIndex: indice,
      onDestinationSelected: onSelect,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 28),
        child: extendido ? const GarlicWordmark() : const GarlicMark(size: 36),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: GEspacio.xl),
            child:
                extendido && config != null
                    ? SizedBox(
                      width: 216,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SyncChip(),
                          const SizedBox(height: GEspacio.m),
                          Text(config.empresaNombre, style: Theme.of(context).textTheme.labelMedium, maxLines: 2),
                          Text(config.evaluadorNombre, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )
                    : const SyncChip(compacto: true),
          ),
        ),
      ),
      destinations: [
        for (final (i, d) in _destinos.indexed)
          NavigationRailDestination(
            icon: i == 3 ? _IconoSync(icono: d.icono) : Icon(d.icono),
            selectedIcon: Icon(d.iconoActivo, color: GColores.primario),
            label: Text(d.etiqueta),
          ),
      ],
    );
  }
}

/// Ícono de sincronizar con insignia de pendientes.
class _IconoSync extends StatelessWidget {
  const _IconoSync({required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<SyncRepository>().resumen;
    final n = r.pendientes + r.errores;
    return Badge(
      isLabelVisible: n > 0,
      backgroundColor: r.errores > 0 ? GColores.error : GColores.acento,
      textColor: r.errores > 0 ? Colors.white : GColores.tinta,
      label: Text('$n'),
      child: Icon(icono),
    );
  }
}
