import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/catalogo.dart';
import '../../../../../domain/models/evaluacion.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/evaluacion_view_model.dart';

/// Paso 6: resumen con promedios (columna PROM del protocolo) y verificación antes de cerrar.
class PasoResumen extends StatelessWidget {
  const PasoResumen({super.key, required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    final b = vm.borrador!;
    final promCalidad = b.promediosCalidad();
    final promCalibres = b.promediosCalibres();
    final pendientes = vm.problemasCierre;
    final primera = f.clasesCalidad.isEmpty ? null : promCalidad[f.clasesCalidad.first.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resultado principal
        Container(
          padding: const EdgeInsets.all(GEspacio.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [GColores.primario, GColores.primarioProfundo]),
            borderRadius: BorderRadius.circular(GRadio.tarjeta),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${f.clasesCalidad.isEmpty ? 'Calidad' : f.clasesCalidad.first.etiqueta} promedio',
                      style: t.labelLarge!.copyWith(color: GColores.acento),
                    ),
                    Text(Formato.porcentaje(primera), style: GTipo.cifra(52, color: Colors.white)),
                    Text(
                      '${b.muestras.length} muestras · ${vm.fotos.length} fotos · ${Formato.fecha(b.fecha)}',
                      style: t.bodySmall!.copyWith(color: Colors.white.withValues(alpha: .8)),
                    ),
                  ],
                ),
              ),
              if (primera != null) _Anillo(valor: primera),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        if (vm.editable) ...[
          if (pendientes.isEmpty)
            const Aviso(mensaje: 'Evaluación completa. Puedes cerrarla.', tipo: TipoAviso.exito)
          else
            SeccionTarjeta(
              titulo: 'Falta para cerrar',
              icono: PhosphorIconsBold.listChecks,
              child: Column(
                children: [
                  for (final p in pendientes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(PhosphorIconsBold.circleDashed, color: GColores.advertencia),
                      title: Text(p.mensaje, style: t.bodyMedium),
                      trailing: TextButton(onPressed: () => vm.irA(p.paso), child: Text('Ir a ${p.paso.titulo}')),
                    ),
                ],
              ),
            ),
          const SizedBox(height: GEspacio.l),
        ],
        SeccionTarjeta(
          titulo: '2.1 Calidad · promedio por muestra',
          icono: PhosphorIconsBold.sealPercent,
          child: _TablaMuestras(vm: vm, opciones: f.clasesCalidad, valores: (m) => m.calidad, promedios: promCalidad),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: '2.2 Calibres · promedio',
          icono: PhosphorIconsBold.ruler,
          child: SizedBox(height: 220, child: _GraficoCalibres(calibres: f.calibres, promedios: promCalibres)),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Sensoriales y sanidad',
          icono: PhosphorIconsBold.drop,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in b.humedad.entries)
                Pastilla(
                  texto: '${f.buscar(e.key)?.etiqueta ?? ''}: ${e.value.etiqueta}',
                  color: GColores.humedad(e.value),
                  icono: PhosphorIconsBold.drop,
                ),
              for (final id in b.empastes)
                Pastilla(texto: 'Empaste ${f.buscar(id)?.etiqueta.toLowerCase() ?? ''}', color: GColores.primario),
              for (final id in b.danos)
                Pastilla(texto: f.buscar(id)?.etiqueta ?? '', color: GColores.tinta, fondo: GColores.superficieAlt),
              for (final e in b.sanidad.entries)
                Pastilla(
                  texto:
                      '${f.buscar(e.key)?.etiqueta ?? ''}: ${e.value.presente ? 'SÍ ${Formato.porcentaje(e.value.porcentaje)}' : 'NO'}',
                  color: e.value.presente ? GColores.error : GColores.secundario,
                  icono: PhosphorIconsBold.virus,
                ),
              if (b.humedad.isEmpty && b.empastes.isEmpty && b.danos.isEmpty && b.sanidad.isEmpty)
                Text('Sin registros', style: t.bodySmall),
            ],
          ),
        ),
        if ((b.observacion ?? '').isNotEmpty) ...[
          const SizedBox(height: GEspacio.l),
          SeccionTarjeta(titulo: 'Observación', icono: PhosphorIconsBold.note, child: Text(b.observacion!)),
        ],
      ],
    );
  }
}

class _Anillo extends StatelessWidget {
  const _Anillo({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 84,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CircularProgressIndicator(
          value: valor / 100,
          strokeWidth: 9,
          backgroundColor: Colors.white.withValues(alpha: .15),
          color: GColores.acento,
          strokeCap: StrokeCap.round,
        ),
        const Center(child: Icon(PhosphorIconsFill.sealCheck, color: Colors.white, size: 30)),
      ],
    ),
  );
}

class _TablaMuestras extends StatelessWidget {
  const _TablaMuestras({required this.vm, required this.opciones, required this.valores, required this.promedios});

  final EvaluacionViewModel vm;
  final List<CatalogoItem> opciones;
  final Map<String, double> Function(MuestraBorrador) valores;
  final Map<String, double> promedios;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muestras = vm.borrador!.muestras;
    const estiloNum = TextStyle(fontFeatures: GTipo.tabular, fontWeight: FontWeight.w600);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48,
        columnSpacing: 22,
        horizontalMargin: 0,
        headingTextStyle: t.labelMedium!.copyWith(color: GColores.tintaSuave),
        columns: [
          const DataColumn(label: Text('')),
          for (final m in muestras) DataColumn(numeric: true, label: Text('M${m.numero}')),
          const DataColumn(
            numeric: true,
            label: Text('PROM', style: TextStyle(color: GColores.primario, fontWeight: FontWeight.w800)),
          ),
        ],
        rows: [
          for (final o in opciones)
            DataRow(
              cells: [
                DataCell(Text(o.etiqueta, style: t.titleSmall)),
                for (final m in muestras) DataCell(Text(Formato.porcentaje(valores(m)[o.id]), style: estiloNum)),
                DataCell(
                  Text(
                    Formato.porcentaje(promedios[o.id]),
                    style: estiloNum.copyWith(color: GColores.primario, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GraficoCalibres extends StatelessWidget {
  const _GraficoCalibres({required this.calibres, required this.promedios});

  final List<CatalogoItem> calibres;
  final Map<String, double> promedios;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (promedios.isEmpty) return Center(child: Text('Sin calibres registrados', style: t.bodySmall));
    final maximo = promedios.values.fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: (maximo * 1.25).clamp(10, 100).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget:
                  (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(calibres[v.toInt()].codigo, style: t.bodySmall),
                  ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => GColores.primarioProfundo,
            getTooltipItem:
                (g, _, r, __) => BarTooltipItem(
                  Formato.porcentaje(r.toY),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
          ),
        ),
        barGroups: [
          for (final (i, c) in calibres.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: promedios[c.id] ?? 0,
                  width: 26,
                  color: GColores.primario,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
