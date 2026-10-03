import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/sync_chip.dart';
import '../view_models/compra_view_model.dart';
import 'pestanas/pestana_cargas.dart';
import 'pestanas/pestana_gastos.dart';
import 'pestanas/pestana_pagos.dart';
import 'pestanas/pestana_precio.dart';
import 'pestanas/pestana_resumen.dart';
import 'widgets/balance_compra.dart';
import 'widgets/formulario_compra.dart';

/// Punto 3 del protocolo: precio, cargas (camiones), gastos vinculados, pagos y balance del lote.
/// En laptop el balance queda fijo a la derecha mientras se trabaja en la pestaña.
class CompraScreen extends StatefulWidget {
  const CompraScreen({super.key, required this.viewModel});

  final CompraViewModel viewModel;

  @override
  State<CompraScreen> createState() => _CompraScreenState();
}

/// El [TabController] manda: al terminar de cambiar de pestaña se informa al ViewModel; si el ViewModel
/// pide otra pestaña (p. ej. "Fijar precio" desde Cargas) se anima el controlador.
class _CompraScreenState extends State<CompraScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: PestanaCompra.values.length,
    initialIndex: widget.viewModel.pestana.index,
    vsync: this,
  );

  CompraViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_alCambiarPestana);
    vm.addListener(_alCambiarViewModel);
  }

  @override
  void dispose() {
    vm.removeListener(_alCambiarViewModel);
    _tabs.dispose();
    super.dispose();
  }

  void _alCambiarPestana() {
    if (!_tabs.indexIsChanging && vm.pestana.index != _tabs.index) vm.irA(PestanaCompra.values[_tabs.index]);
  }

  void _alCambiarViewModel() {
    if (!_tabs.indexIsChanging && vm.pestana.index != _tabs.index) _tabs.animateTo(vm.pestana.index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([vm, _tabs]),
      builder: (context, _) {
        final lote = vm.lote;
        final t = Theme.of(context).textTheme;
        final ancho = AnchoVentana.of(context);
        // durante la animación se muestra lo de la pestaña destino
        final pestana = PestanaCompra.values[_tabs.index];
        return Scaffold(
          floatingActionButton: lote == null || vm.compra == null ? null : _boton(context, vm, pestana),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compra y pagos', style: t.titleLarge),
                if (lote != null) Text('${lote.codigo} · Zona ${lote.zona}', style: t.bodySmall),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Actualizar desde el servidor',
                onPressed: vm.refrescar.running ? null : () => vm.refrescar.execute(),
                icon: const Icon(PhosphorIconsBold.arrowsClockwise),
              ),
              const Padding(padding: EdgeInsets.only(right: GEspacio.m), child: SyncChip(compacto: true)),
            ],
            bottom: TabBar(
              isScrollable: ancho.esCompacto,
              tabAlignment: ancho.esCompacto ? TabAlignment.start : TabAlignment.fill,
              controller: _tabs,
              tabs: [for (final p in PestanaCompra.values) Tab(text: _titulo(vm, p))],
            ),
          ),
          body:
              lote == null || vm.compra == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      if (!vm.editable)
                        const Padding(
                          padding: EdgeInsets.all(GEspacio.l),
                          child: Aviso(mensaje: 'El lote está anulado: solo lectura.', tipo: TipoAviso.advertencia),
                        ),
                      if (!vm.catalogosCompra && vm.editable)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 0),
                          child: Aviso(
                            mensaje:
                                'Faltan catálogos de compra (empaques, gastos, condiciones de pago). '
                                'Ve a Sincronizar → Actualizar catálogos.',
                            tipo: TipoAviso.advertencia,
                          ),
                        ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TabBarView(
                                controller: _tabs,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  PestanaPrecio(vm: vm),
                                  PestanaCargas(vm: vm),
                                  PestanaGastos(vm: vm),
                                  PestanaPagos(vm: vm),
                                  PestanaResumen(vm: vm),
                                ],
                              ),
                            ),
                            // fijo en laptop: quitarlo al cambiar de pestaña altera el ancho a mitad de la animación
                            if (ancho.esExpandido)
                              SizedBox(
                                width: 360,
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(0, GEspacio.l, GEspacio.l, GEspacio.l),
                                  children: [BalanceCompraPanel(vm: vm)],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }

  /// Un solo botón flotante según la pestaña activa (así no se toca el de otra pestaña durante la animación).
  static Widget? _boton(BuildContext context, CompraViewModel vm, PestanaCompra pestana) {
    if (!vm.editable) return null;
    final (texto, icono, formulario) = switch (pestana) {
      PestanaCompra.cargas => (
        'Agregar camión',
        PhosphorIconsBold.truck,
        () => FormularioCarga(vm: vm, carga: vm.nuevaCarga(), nueva: true),
      ),
      PestanaCompra.gastos when vm.tiposGasto.isNotEmpty => (
        'Agregar gasto',
        PhosphorIconsBold.receipt,
        () => FormularioGasto(vm: vm, gasto: vm.nuevoGasto(), nuevo: true),
      ),
      PestanaCompra.pagos when vm.condicionesPago.isNotEmpty => (
        'Registrar pago',
        PhosphorIconsBold.money,
        () => FormularioPago(vm: vm, pago: vm.nuevoPago(), nuevo: true),
      ),
      _ => (null, null, null),
    };
    if (formulario == null) return null;
    return FloatingActionButton.extended(
      onPressed: () => abrirFormularioCompra(context, formulario()),
      icon: Icon(icono),
      label: Text(texto!),
    );
  }

  static String _titulo(CompraViewModel vm, PestanaCompra p) {
    final c = vm.compra;
    final n = switch (p) {
      PestanaCompra.cargas => c?.cargas.length,
      PestanaCompra.gastos => c?.gastos.length,
      PestanaCompra.pagos => c?.pagos.length,
      _ => null,
    };
    return n == null || n == 0 ? p.titulo : '${p.titulo} ($n)';
  }
}
