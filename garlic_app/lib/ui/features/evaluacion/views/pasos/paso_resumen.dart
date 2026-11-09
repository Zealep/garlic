import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/catalogo.dart';
import '../../../../../domain/models/evaluacion.dart';
import '../../../../../domain/use_cases/reglas_evaluacion.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';
import '../../../../core/widgets/resultado_evaluacion.dart';
import '../../view_models/evaluacion_view_model.dart';

/// Último paso: resumen con promedios (columna PROM del protocolo) y verificación antes de cerrar.
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
        const SizedBox(height: GEspacio.m),
        _DesgloseFotos(vm: vm),
        const SizedBox(height: GEspacio.l),
        if (!vm.editable) ...[_Resultado(vm: vm), const SizedBox(height: GEspacio.l)],
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
                      trailing: TextButton(
                        onPressed: () => vm.irAProblema(p),
                        child: Text(p.muestra == null ? 'Ir a ${p.paso.titulo}' : 'Ir a M${p.muestra}'),
                      ),
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
          child: SizedBox(
            height: 220,
            child: _GraficoCalibres(
              // solo los calibres usados en la evaluación, en el orden del catálogo
              calibres: f.calibres.where((c) => promCalibres.containsKey(c.id)).toList(),
              promedios: promCalibres,
            ),
          ),
        ),
        if (f.tiposDano.any((d) => d.pideCantidades)) ...[const SizedBox(height: GEspacio.l), _Paralisis(vm: vm)],
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Sanidad · incidencia por muestra',
          icono: PhosphorIconsBold.virus,
          child:
              f.enfermedades.isEmpty
                  ? Text('Sin enfermedades a evaluar en campo', style: t.bodySmall)
                  : _TablaMuestras(
                    vm: vm,
                    opciones: f.enfermedades,
                    valores:
                        (m) => {
                          for (final e in m.sanidad.entries) e.key: e.value.presente ? (e.value.porcentaje ?? 0) : 0,
                        },
                    promedios: b.promediosSanidad(),
                  ),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Sensoriales por muestra',
          icono: PhosphorIconsBold.drop,
          child: _TablaSensoriales(vm: vm),
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
        // el % se ve siempre sobre cada barra, sin tocarla
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItem:
                (g, _, r, __) => BarTooltipItem(
                  Formato.porcentaje(r.toY),
                  const TextStyle(color: GColores.primarioProfundo, fontWeight: FontWeight.w800, fontSize: 13),
                ),
          ),
        ),
        barGroups: [
          for (final (i, c) in calibres.indexed)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: const [0],
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

/// Parálisis (daños con cantidades): dato clave del lote, en grande. % por muestra y promedio.
class _Paralisis extends StatelessWidget {
  const _Paralisis({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = vm.borrador!;
    final prom = b.promediosDanos();
    final tipos = vm.formulario!.tiposDano.where((d) => d.pideCantidades).toList();
    return Container(
      padding: const EdgeInsets.all(GEspacio.l),
      decoration: BoxDecoration(
        color: GColores.errorSuave,
        borderRadius: BorderRadius.circular(GRadio.tarjeta),
        border: Border.all(color: GColores.error.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsBold.warningOctagon, color: GColores.error),
              const SizedBox(width: GEspacio.s),
              Expanded(child: Text('Parálisis · % de daño', style: t.titleLarge!.copyWith(color: GColores.error))),
            ],
          ),
          for (final d in tipos) ...[
            const SizedBox(height: GEspacio.m),
            Text(d.etiqueta, style: t.titleSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  prom[d.id] == null ? '0%' : Formato.porcentaje(prom[d.id]),
                  style: GTipo.cifra(44, color: GColores.error),
                ),
                const SizedBox(width: GEspacio.s),
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('promedio', style: t.bodySmall)),
              ],
            ),
            Wrap(
              spacing: GEspacio.s,
              runSpacing: GEspacio.xs,
              children: [
                for (final m in b.muestras)
                  Pastilla(
                    texto: 'M${m.numero}: ${_porMuestra(m.danos[d.id])}',
                    color: m.danos[d.id] == null ? GColores.tintaSuave : GColores.error,
                    fondo: GColores.superficie,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _porMuestra(DanoBorrador? d) {
    if (d == null) return 'no';
    if (d.porcentaje == null) return 'sin conteo';
    return '${Formato.porcentaje(d.porcentaje)} (${d.afectados}/${d.total})';
  }
}

/// Humedad (SI/NO) y empaste de cada muestra (los daños van en el bloque de parálisis).
class _TablaSensoriales extends StatelessWidget {
  const _TablaSensoriales({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    final muestras = vm.borrador!.muestras;
    final otrosDanos = {
      for (final d in f.tiposDano)
        if (!d.pideCantidades && !d.esExcluyente) d.id,
    };
    String nombres(Iterable<String> ids) =>
        ids.isEmpty ? '—' : ids.map((id) => f.buscar(id)?.etiqueta ?? '—').join(', ');
    Widget celda(String texto, {Color? color}) =>
        Text(texto, style: t.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: color));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 52,
        columnSpacing: 18,
        horizontalMargin: 0,
        headingTextStyle: t.labelMedium!.copyWith(color: GColores.tintaSuave),
        columns: [const DataColumn(label: Text('')), for (final m in muestras) DataColumn(label: Text('M${m.numero}'))],
        rows: [
          for (final h in f.tiposHumedad)
            DataRow(
              cells: [
                DataCell(Text(h.etiqueta, style: t.titleSmall)),
                for (final m in muestras)
                  DataCell(switch (m.humedad[h.id]) {
                    true => celda('SÍ', color: GColores.error),
                    false => celda('NO', color: GColores.secundario),
                    null => celda('—'),
                  }),
              ],
            ),
          DataRow(
            cells: [
              DataCell(Text('Empaste', style: t.titleSmall)),
              for (final m in muestras) DataCell(celda(nombres(m.empastes))),
            ],
          ),
          // Las parálisis (con cantidades) y "NO CONTIENE" ya se ven en el bloque de parálisis;
          // aquí solo los daños sin cantidades que se agreguen al catálogo.
          if (otrosDanos.isNotEmpty)
            DataRow(
              cells: [
                DataCell(Text('Otros daños', style: t.titleSmall)),
                for (final m in muestras) DataCell(celda(nombres(m.danos.keys.where(otrosDanos.contains)))),
              ],
            ),
        ],
      ),
    );
  }
}

/// Cuántas fotos hay en cada sección (las fotos se toman dentro de cada paso).
class _DesgloseFotos extends StatelessWidget {
  const _DesgloseFotos({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final grupos = [
      ('Generales', vm.fotosGenerales.length, PasoEvaluacion.general),
      ('Muestras', vm.fotos.where((f) => SeccionFoto.de(f) == SeccionFoto.muestra).length, PasoEvaluacion.muestras),
    ];
    return Wrap(
      spacing: GEspacio.s,
      runSpacing: GEspacio.s,
      children: [
        for (final (nombre, n, paso) in grupos)
          ActionChip(
            avatar: const Icon(PhosphorIconsBold.camera, size: 16, color: GColores.primario),
            label: Text('$nombre · $n'),
            onPressed: () => vm.irA(paso),
          ),
      ],
    );
  }
}

/// Dictamen tras cerrar: aceptada, rechazada o sin acuerdo de precio con el agricultor. Se puede corregir.
class _Resultado extends StatefulWidget {
  const _Resultado({required this.vm});

  final EvaluacionViewModel vm;

  @override
  State<_Resultado> createState() => _ResultadoState();
}

class _ResultadoState extends State<_Resultado> {
  late final _motivo = TextEditingController(text: widget.vm.borrador!.motivoResultado);

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final actual = widget.vm.borrador!.resultado;
    final (color, icono) = estiloResultado(actual);
    return SeccionTarjeta(
      titulo: 'Resultado de la evaluación',
      icono: PhosphorIconsBold.gavel,
      accion: Pastilla(texto: actual?.etiqueta ?? 'Pendiente', color: color, icono: icono),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Defínelo cuando se decida con el agricultor. No impide registrar la compra '
            '(un lote rechazado puede comprarse por necesidad de producto).',
            style: t.bodySmall,
          ),
          const SizedBox(height: GEspacio.m),
          Wrap(
            spacing: GEspacio.s,
            runSpacing: GEspacio.s,
            children: [
              for (final r in ResultadoEvaluacion.values)
                ChoiceChip(
                  avatar: Icon(estiloResultado(r).$2, size: 18, color: estiloResultado(r).$1),
                  label: Text(r.etiqueta),
                  selected: actual == r,
                  onSelected: (sel) => widget.vm.definirResultado(sel ? r : null, motivo: _motivo.text),
                ),
            ],
          ),
          if (actual == ResultadoEvaluacion.rechazada || actual == ResultadoEvaluacion.sinAcuerdo) ...[
            const SizedBox(height: GEspacio.m),
            TextField(
              controller: _motivo,
              maxLength: 500,
              decoration: InputDecoration(
                labelText:
                    actual == ResultadoEvaluacion.sinAcuerdo ? 'Motivo (ej. precio que pide)' : 'Motivo del rechazo',
                suffixIcon: IconButton(
                  tooltip: 'Guardar motivo',
                  icon: const Icon(PhosphorIconsBold.floppyDisk),
                  onPressed: () async {
                    await widget.vm.definirResultado(actual, motivo: _motivo.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Motivo guardado')));
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
