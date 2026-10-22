import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/evaluacion.dart';
import '../../../../domain/models/formulario.dart';
import '../../../../domain/use_cases/comparacion_evaluaciones.dart';
import '../../../../domain/use_cases/seguimiento_lotes.dart';
import '../../../../routing/rutas.dart';
import '../../../../utils/formato.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/campo_numero.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/resultado_evaluacion.dart';
import '../../../core/widgets/seguimiento.dart';
import '../view_models/comparacion_view_model.dart';

const _colorA = GColores.primario;
const _colorB = GColores.acento;

/// Dos evaluaciones lado a lado: resalta el mejor valor donde la dirección es clara y calcula
/// el valor por kg de ambas con los mismos precios base.
class ComparacionScreen extends StatelessWidget {
  const ComparacionScreen({super.key, required this.viewModel});

  final ComparacionViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([viewModel, viewModel.cargar]),
    builder: (context, _) {
      final vm = viewModel;
      final c = vm.comparacion;
      if (c == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Comparar evaluaciones')),
          body:
              vm.cargar.failure != null
                  ? EstadoVacio(
                    titulo: 'No se pudo comparar',
                    mensaje: vm.cargar.failure!.message,
                    accion: FilledButton(onPressed: vm.cargar.execute, child: const Text('Reintentar')),
                  )
                  : const Center(child: CircularProgressIndicator()),
        );
      }
      final compacto = AnchoVentana.of(context).esCompacto;
      final f = vm.formulario!;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Comparar evaluaciones'),
          actions: [
            IconButton(
              tooltip: 'Intercambiar',
              onPressed: vm.intercambiar,
              icon: const Icon(PhosphorIconsBold.arrowsLeftRight),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compacto ? GEspacio.m : GEspacio.l,
            GEspacio.s,
            compacto ? GEspacio.m : GEspacio.l,
            GEspacio.xxxl,
          ),
          child: AnchoMaximo(
            max: 980,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _Cabecera(lado: vm.a!, letra: 'A', color: _colorA)),
                      const SizedBox(width: GEspacio.s),
                      Expanded(child: _Cabecera(lado: vm.b!, letra: 'B', color: _colorB)),
                    ],
                  ),
                ),
                const SizedBox(height: GEspacio.m),
                _Marcador(comparacion: c),
                const SizedBox(height: GEspacio.l),
                _ValorPorKg(vm: vm, comparacion: c),
                const SizedBox(height: GEspacio.l),
                SeccionTarjeta(
                  titulo: 'Calidad · promedio',
                  icono: PhosphorIconsBold.sealPercent,
                  child: _Tabla(
                    filas: [for (final fila in c.calidad) _FilaVista.de(fila, Formato.porcentaje, diferencia: _puntos)],
                  ),
                ),
                const SizedBox(height: GEspacio.l),
                SeccionTarjeta(
                  titulo: 'Calibres · promedio',
                  icono: PhosphorIconsBold.ruler,
                  accion: const _Leyenda(),
                  child: _GraficoCalibres(filas: c.calibres),
                ),
                const SizedBox(height: GEspacio.l),
                SeccionTarjeta(
                  titulo: 'Sensoriales y sanidad',
                  icono: PhosphorIconsBold.drop,
                  child: _Tabla(
                    filas: [
                      ..._sensoriales(f, vm.a!.evaluacion, vm.b!.evaluacion),
                      for (final fila in c.sanidadYDanos)
                        _FilaVista.de(
                          fila,
                          fila.id == 'incidencia' ? Formato.porcentaje : (v) => v?.toInt().toString() ?? '—',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: GEspacio.l),
                SeccionTarjeta(
                  titulo: 'Resultado y observaciones',
                  icono: PhosphorIconsBold.gavel,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _Observaciones(evaluacion: vm.a!.evaluacion, formulario: f)),
                        const VerticalDivider(width: GEspacio.xl),
                        Expanded(child: _Observaciones(evaluacion: vm.b!.evaluacion, formulario: f)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  static String _puntos(double d) => '${d > 0 ? '+' : ''}${Formato.porcentaje(d).replaceAll('%', '')} pp';

  /// Humedad por tipo y empastes: se muestran, sin ganador (depende del uso del producto).
  static List<_FilaVista> _sensoriales(FormularioEvaluacion f, EvaluacionBorrador a, EvaluacionBorrador b) {
    final tipos = [
      for (final t in f.tiposHumedad)
        if (a.humedad.containsKey(t.id) || b.humedad.containsKey(t.id)) t,
    ];
    String empastes(EvaluacionBorrador e) =>
        e.empastes.isEmpty ? 'Ninguno' : e.empastes.map((id) => f.buscar(id)?.etiqueta ?? '—').join(', ');
    return [
      for (final t in tipos)
        _FilaVista(etiqueta: t.etiqueta, a: a.humedad[t.id]?.etiqueta ?? '—', b: b.humedad[t.id]?.etiqueta ?? '—'),
      _FilaVista(etiqueta: 'Empaste', a: empastes(a), b: empastes(b)),
    ];
  }
}

/// Lote y evaluación de un lado; al tocarla abre la evaluación.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.lado, required this.letra, required this.color});

  final LadoComparacion lado;
  final String letra;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ev = lado.evaluacion;
    final lote = lado.lote;
    final dias = SeguimientoLotes.diasParaCorte(lote, DateTime.now());
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GRadio.tarjeta),
        side: BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        onTap: () => context.push(Rutas.evaluacion(lote.id, ev.id)),
        child: Padding(
          padding: const EdgeInsets.all(GEspacio.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Letra(letra: letra, color: color),
                  const SizedBox(width: GEspacio.s),
                  Expanded(
                    child: Text(lote.codigo, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: GEspacio.xs),
              Text(
                [lote.zona, lote.variedad.texto].where((s) => s.isNotEmpty).join(' · '),
                style: t.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(lote.agricultor.nombres, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                [
                  Formato.fecha(ev.fecha),
                  '${ev.muestras.length} muestras',
                  if (lado.resumen?.evaluador != null) lado.resumen!.evaluador!,
                ].join(' · '),
                style: t.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const SizedBox(height: GEspacio.s),
              for (final p in [
                PastillaEstadoEvaluacion(estado: ev.estado, resultado: ev.resultado),
                if (dias != null) PastillaCorte(dias: dias),
                if (lado.precioPactado != null)
                  Pastilla(
                    texto: 'Pactado ${Formato.precioKg(lado.precioPactado)}',
                    color: GColores.tinta,
                    fondo: GColores.acentoSuave,
                  ),
              ])
                Padding(padding: const EdgeInsets.only(top: 4), child: _Ajustada(child: p)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Achica una pastilla si no cabe en media pantalla (celulares angostos).
class _Ajustada extends StatelessWidget {
  const _Ajustada({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
}

class _Letra extends StatelessWidget {
  const _Letra({required this.letra, required this.color});

  final String letra;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Text(letra, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
  );
}

/// Cuántas filas con dirección gana cada una (no es un puntaje: todas pesan igual).
class _Marcador extends StatelessWidget {
  const _Marcador({required this.comparacion});

  final ComparacionEvaluaciones comparacion;

  @override
  Widget build(BuildContext context) {
    final a = comparacion.ganadas(Ganador.a);
    final b = comparacion.ganadas(Ganador.b);
    final empates = comparacion.ganadas(Ganador.empate);
    return Aviso(
      tipo: TipoAviso.info,
      mensaje:
          'A es mejor en $a · B es mejor en $b${empates > 0 ? ' · $empates parejos' : ''}. '
          'Se resalta solo lo que tiene un mejor claro: % de primera, valor por kg, sanidad y daños.',
    );
  }
}

/// Precios base comunes → precio técnico de cada evaluación (misma fórmula que la fijación de precio).
class _ValorPorKg extends StatelessWidget {
  const _ValorPorKg({required this.vm, required this.comparacion});

  final ComparacionViewModel vm;
  final ComparacionEvaluaciones comparacion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fila = comparacion.valorKg;
    final d = fila.diferencia;
    final nota = switch (fila.ganador) {
      null => 'Ingresa los precios base para ver cuánto vale cada kg.',
      Ganador.empate => 'Con estos precios, ambas valen prácticamente lo mismo por kg.',
      Ganador.a => 'Con estos precios, A vale ${Formato.precioKg(-d!)} más por kg.',
      Ganador.b => 'Con estos precios, B vale ${Formato.precioKg(d!)} más por kg.',
    };
    return SeccionTarjeta(
      titulo: 'Valor por kg',
      icono: PhosphorIconsBold.currencyCircleDollar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mismos precios base para las dos: precio técnico = promedio de muestras − llenado.',
            style: t.bodySmall,
          ),
          const SizedBox(height: GEspacio.m),
          Wrap(
            spacing: GEspacio.m,
            runSpacing: GEspacio.m,
            children: [
              for (final c in vm.clasesCalidad)
                SizedBox(
                  width: 132,
                  child: CampoNumero(
                    etiqueta: c.etiqueta,
                    prefijo: 'S/ ',
                    decimales: 4,
                    valor: vm.preciosBase[c.id],
                    onChanged: (v) => vm.setPrecioBase(c.id, v),
                  ),
                ),
              SizedBox(
                width: 132,
                child: CampoNumero(
                  etiqueta: 'Llenado',
                  prefijo: 'S/ ',
                  decimales: 4,
                  valor: vm.gastoLlenado == 0 ? null : vm.gastoLlenado,
                  onChanged: vm.setGastoLlenado,
                ),
              ),
            ],
          ),
          const SizedBox(height: GEspacio.l),
          Row(
            children: [
              Expanded(child: _Cifra(letra: 'A', color: _colorA, valor: fila.a, gana: fila.ganador == Ganador.a)),
              const SizedBox(width: GEspacio.s),
              Expanded(child: _Cifra(letra: 'B', color: _colorB, valor: fila.b, gana: fila.ganador == Ganador.b)),
            ],
          ),
          const SizedBox(height: GEspacio.s),
          Text(nota, style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.letra, required this.color, required this.valor, required this.gana});

  final String letra;
  final Color color;
  final double? valor;
  final bool gana;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(GEspacio.m),
    decoration: BoxDecoration(
      color: gana ? GColores.secundarioSuave : GColores.superficieAlt,
      borderRadius: BorderRadius.circular(GRadio.chico),
    ),
    child: Row(
      children: [
        _Letra(letra: letra, color: color),
        const SizedBox(width: GEspacio.s),
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(Formato.precioKg(valor), style: GTipo.cifra(24)),
          ),
        ),
        if (gana) const Icon(PhosphorIconsFill.checkCircle, color: GColores.secundario, size: 22),
      ],
    ),
  );
}

/// Fila ya formateada para la tabla A | B | Δ.
class _FilaVista {
  const _FilaVista({required this.etiqueta, required this.a, required this.b, this.delta, this.ganador});

  factory _FilaVista.de(FilaComparacion f, String Function(double?) formato, {String Function(double)? diferencia}) =>
      _FilaVista(
        etiqueta: f.etiqueta,
        a: formato(f.a),
        b: formato(f.b),
        delta: diferencia == null || f.diferencia == null || f.diferencia == 0 ? null : diferencia(f.diferencia!),
        ganador: f.ganador,
      );

  final String etiqueta;
  final String a;
  final String b;

  /// B − A formateado.
  final String? delta;
  final Ganador? ganador;
}

class _Tabla extends StatelessWidget {
  const _Tabla({required this.filas});

  final List<_FilaVista> filas;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final conDelta = filas.any((f) => f.delta != null);
    final encabezado = t.labelMedium!.copyWith(color: GColores.tintaSuave);
    return Table(
      columnWidths: {
        0: const FlexColumnWidth(2.2),
        1: const FlexColumnWidth(1.6),
        2: const FlexColumnWidth(1.6),
        if (conDelta) 3: const FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox(),
            const Padding(padding: EdgeInsets.only(bottom: 6), child: _Encabezado(letra: 'A', color: _colorA)),
            const Padding(padding: EdgeInsets.only(bottom: 6), child: _Encabezado(letra: 'B', color: _colorB)),
            if (conDelta) Text('B − A', style: encabezado, textAlign: TextAlign.end),
          ],
        ),
        for (final f in filas)
          TableRow(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: GColores.borde))),
            children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(f.etiqueta, style: t.titleSmall)),
              _Celda(texto: f.a, gana: f.ganador == Ganador.a),
              _Celda(texto: f.b, gana: f.ganador == Ganador.b),
              if (conDelta)
                Text(
                  f.delta ?? '',
                  textAlign: TextAlign.end,
                  style: t.bodySmall!.copyWith(fontFeatures: GTipo.tabular),
                ),
            ],
          ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.letra, required this.color});

  final String letra;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.centerLeft, child: _Letra(letra: letra, color: color));
}

class _Celda extends StatelessWidget {
  const _Celda({required this.texto, required this.gana});

  final String texto;
  final bool gana;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: GEspacio.xs),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: gana ? BoxDecoration(color: GColores.secundarioSuave, borderRadius: BorderRadius.circular(8)) : null,
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                texto,
                maxLines: 1,
                style: TextStyle(
                  fontFeatures: GTipo.tabular,
                  fontWeight: gana ? FontWeight.w800 : FontWeight.w600,
                  color: gana ? GColores.secundario : GColores.tinta,
                ),
              ),
            ),
          ),
          if (gana) ...[
            const SizedBox(width: 4),
            const Icon(PhosphorIconsBold.check, size: 14, color: GColores.secundario),
          ],
        ],
      ),
    ),
  );
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [_Letra(letra: 'A', color: _colorA), SizedBox(width: 6), _Letra(letra: 'B', color: _colorB)],
  );
}

class _GraficoCalibres extends StatelessWidget {
  const _GraficoCalibres({required this.filas});

  final List<FilaComparacion> filas;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (filas.isEmpty) return Text('Sin calibres registrados', style: t.bodySmall);
    final maximo = filas.expand((f) => [f.a ?? 0, f.b ?? 0]).fold<double>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 220,
      child: BarChart(
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
                      child: Text(filas[v.toInt()].etiqueta, style: t.bodySmall),
                    ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => GColores.primarioProfundo,
              getTooltipItem:
                  (g, _, r, i) => BarTooltipItem(
                    '${i == 0 ? 'A' : 'B'} ${Formato.porcentaje(r.toY)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
            ),
          ),
          barGroups: [
            for (final (i, f) in filas.indexed)
              BarChartGroupData(
                x: i,
                barsSpace: 3,
                barRods: [
                  for (final (valor, color) in [(f.a ?? 0, _colorA), (f.b ?? 0, _colorB)])
                    BarChartRodData(
                      toY: valor,
                      width: 12,
                      color: color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Resultado, motivo, sanidad presente, daños y observación de un lado.
class _Observaciones extends StatelessWidget {
  const _Observaciones({required this.evaluacion, required this.formulario});

  final EvaluacionBorrador evaluacion;
  final FormularioEvaluacion formulario;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = evaluacion;
    final enfermedades = [
      for (final s in e.sanidad.entries)
        if (s.value.presente) '${formulario.buscar(s.key)?.etiqueta ?? '—'} ${Formato.porcentaje(s.value.porcentaje)}',
    ];
    final danos = [for (final id in e.danos) formulario.buscar(id)?.etiqueta ?? '—'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Ajustada(child: PastillaEstadoEvaluacion(estado: e.estado, resultado: e.resultado)),
        if ((e.motivoResultado ?? '').isNotEmpty) ...[
          const SizedBox(height: GEspacio.xs),
          Text(e.motivoResultado!, style: t.bodySmall),
        ],
        const SizedBox(height: GEspacio.s),
        Text('Sanidad', style: t.labelMedium!.copyWith(color: GColores.tintaSuave)),
        Text(enfermedades.isEmpty ? 'Sin enfermedades' : enfermedades.join(', '), style: t.bodyMedium),
        const SizedBox(height: GEspacio.s),
        Text('Daños', style: t.labelMedium!.copyWith(color: GColores.tintaSuave)),
        Text(danos.isEmpty ? 'Ninguno' : danos.join(', '), style: t.bodyMedium),
        if ((e.observacion ?? '').isNotEmpty) ...[
          const SizedBox(height: GEspacio.s),
          Text('Observación', style: t.labelMedium!.copyWith(color: GColores.tintaSuave)),
          Text(e.observacion!, style: t.bodyMedium),
        ],
      ],
    );
  }
}
