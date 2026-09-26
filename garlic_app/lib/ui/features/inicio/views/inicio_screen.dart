import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/sync_repository.dart';
import '../../../../routing/rutas.dart';
import '../../../../utils/formato.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/evaluacion_tile.dart';
import '../../../core/widgets/marca.dart';
import '../../../core/widgets/selector_lote.dart';
import '../../../core/widgets/sync_chip.dart';
import '../view_models/inicio_view_model.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key, required this.viewModel});

  final InicioViewModel viewModel;

  Future<void> _nuevaEvaluacion(BuildContext context) async {
    final lote = await seleccionarLote(context, viewModel.lotesActivos);
    if (lote != null && context.mounted) await context.push(Rutas.evaluar(lote.id));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final ancho = AnchoVentana.of(context);
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => viewModel.refrescar.execute(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Encabezado(vm: viewModel, ancho: ancho, onNueva: () => _nuevaEvaluacion(context)),
                ),
                SliverToBoxAdapter(
                  child: AnchoMaximo(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.xl, GEspacio.l, 120),
                      child:
                          ancho.esExpandido
                              ? _Tablero(vm: viewModel)
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Kpis(vm: viewModel, columnas: ancho.esCompacto ? 2 : 4),
                                  const SizedBox(height: GEspacio.xxl),
                                  _Recientes(vm: viewModel),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.vm, required this.ancho, required this.onNueva});

  final InicioViewModel vm;
  final AnchoVentana ancho;
  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hoy = DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());
    return FondoMarca(
      child: SafeArea(
        bottom: false,
        child: AnchoMaximo(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(GEspacio.xl, GEspacio.l, GEspacio.xl, GEspacio.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (ancho.esCompacto) const GarlicWordmark(claro: true, compacto: true),
                    const Spacer(),
                    const SyncChip(sobreOscuro: true),
                  ],
                ),
                SizedBox(height: ancho.esCompacto ? GEspacio.xxl : GEspacio.l),
                Text(
                  '${hoy[0].toUpperCase()}${hoy.substring(1)}',
                  style: t.labelLarge!.copyWith(color: GColores.acento),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.evaluador.isEmpty ? 'Buen día' : 'Buen día, ${vm.evaluador}',
                  style: t.headlineMedium!.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(vm.empresa, style: t.bodyMedium!.copyWith(color: Colors.white.withValues(alpha: .75))),
                const SizedBox(height: GEspacio.xl),
                _CtaNueva(onTap: onNueva, lotes: vm.lotesActivos.length),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción principal del día: evaluar un lote.
class _CtaNueva extends StatelessWidget {
  const _CtaNueva({required this.onTap, required this.lotes});

  final VoidCallback onTap;
  final int lotes;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: GColores.acento,
      borderRadius: BorderRadius.circular(GRadio.tarjeta),
      child: InkWell(
        borderRadius: BorderRadius.circular(GRadio.tarjeta),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GEspacio.l),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GColores.tinta.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsBold.clipboardText, color: GColores.tinta, size: 26),
              ),
              const SizedBox(width: GEspacio.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nueva evaluación', style: t.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                    Text('$lotes lotes activos para evaluar', style: t.bodySmall!.copyWith(color: GColores.tinta)),
                  ],
                ),
              ),
              const Icon(PhosphorIconsBold.arrowRight, color: GColores.tinta),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.vm, required this.columnas});

  final InicioViewModel vm;
  final int columnas;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncRepository>().resumen;
    final tarjetas = [
      KpiCard(
        titulo: 'Lotes activos',
        valor: '${vm.lotesActivos.length}',
        icono: PhosphorIconsBold.plant,
        onTap: () => context.go(Rutas.lotes),
      ),
      KpiCard(
        titulo: 'En borrador',
        valor: '${vm.borradores}',
        icono: PhosphorIconsBold.pencilSimpleLine,
        color: GColores.advertencia,
        fondo: GColores.advertenciaSuave,
        onTap: () => context.go(Rutas.evaluaciones),
      ),
      KpiCard(
        titulo: 'Cerradas',
        valor: '${vm.cerradas}',
        icono: PhosphorIconsBold.sealCheck,
        color: GColores.secundario,
        fondo: GColores.secundarioSuave,
        detalle: vm.calidadPromedio == null ? null : 'Primera prom. ${Formato.porcentaje(vm.calidadPromedio)}',
        onTap: () => context.go(Rutas.evaluaciones),
      ),
      KpiCard(
        titulo: 'Por sincronizar',
        valor: '${sync.pendientes + sync.errores}',
        icono: PhosphorIconsBold.cloudArrowUp,
        color: sync.errores > 0 ? GColores.error : GColores.info,
        fondo: sync.errores > 0 ? GColores.errorSuave : const Color(0xFFE3EEF7),
        detalle: 'Última: ${Formato.relativo(sync.ultimaSincronizacion)}',
        onTap: () => context.go(Rutas.sync),
      ),
    ];
    return GridView.count(
      crossAxisCount: columnas,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: GEspacio.m,
      crossAxisSpacing: GEspacio.m,
      childAspectRatio: columnas == 2 ? 1.18 : 1.9,
      children: tarjetas,
    );
  }
}

class _Recientes extends StatelessWidget {
  const _Recientes({required this.vm});

  final InicioViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Evaluaciones recientes', style: t.titleLarge)),
            TextButton(onPressed: () => context.go(Rutas.evaluaciones), child: const Text('Ver todas')),
          ],
        ),
        const SizedBox(height: GEspacio.s),
        if (vm.recientes.isEmpty)
          const Card(
            child: EstadoVacio(
              titulo: 'Aún no hay evaluaciones',
              mensaje: 'Empieza evaluando un lote: registra muestras, humedad y sanidad en minutos.',
            ),
          )
        else
          for (final e in vm.recientes) ...[
            EvaluacionTile(evaluacion: e, onTap: () => context.push(Rutas.evaluacion(e.loteId, e.id))),
            const SizedBox(height: GEspacio.s),
          ],
      ],
    );
  }
}

/// Vista de laptop: indicadores + gráfico de calidad + recientes lado a lado.
class _Tablero extends StatelessWidget {
  const _Tablero({required this.vm});

  final InicioViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Kpis(vm: vm, columnas: 4),
        const SizedBox(height: GEspacio.xxl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _GraficoCalidad(vm: vm)),
            const SizedBox(width: GEspacio.xl),
            Expanded(flex: 4, child: _Recientes(vm: vm)),
          ],
        ),
      ],
    );
  }
}

class _GraficoCalidad extends StatelessWidget {
  const _GraficoCalidad({required this.vm});

  final InicioViewModel vm;

  @override
  Widget build(BuildContext context) {
    final datos = vm.conCalidad.reversed.toList();
    final t = Theme.of(context).textTheme;
    return SeccionTarjeta(
      titulo: '% de primera por evaluación',
      icono: PhosphorIconsBold.chartBar,
      child: SizedBox(
        height: 280,
        child:
            datos.isEmpty
                ? Center(child: Text('Las evaluaciones hechas en este equipo aparecerán aquí', style: t.bodySmall))
                : BarChart(
                  BarChartData(
                    maxY: 100,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) => const FlLine(color: GColores.borde, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 25,
                          getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: t.bodySmall),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget:
                              (v, _) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(datos[v.toInt()].loteCodigo.replaceAll('LOTE ', 'L'), style: t.bodySmall),
                              ),
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => GColores.primarioProfundo,
                        getTooltipItem:
                            (g, _, r, __) => BarTooltipItem(
                              '${datos[g.x].loteCodigo}\n${Formato.porcentaje(r.toY)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                      ),
                    ),
                    barGroups: [
                      for (final (i, e) in datos.indexed)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: e.promedioPrimera!,
                              width: 22,
                              color: e.promedioPrimera! >= 80 ? GColores.secundario : GColores.acento,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: GColores.superficieAlt,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
