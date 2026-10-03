import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../routing/rutas.dart';
import '../../../../../utils/formato.dart';
import '../../../../../utils/result.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campo_numero.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/compra_view_model.dart';

/// Módulo de fijación de precio: precio base por clase de calidad × % de cada muestra, promedio,
/// menos gasto de llenado = precio técnico; luego el precio pactado con el agricultor.
class PestanaPrecio extends StatelessWidget {
  const PestanaPrecio({super.key, required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.fijacion;
    if (f == null) {
      return ListView(
        padding: const EdgeInsets.all(GEspacio.l),
        children: [
          Card(
            child: EstadoVacio(
              titulo: 'Primero cierra una evaluación',
              mensaje: 'El precio se calcula con los % de calidad de las muestras de una evaluación cerrada del lote.',
              accion:
                  vm.editable
                      ? FilledButton.icon(
                        onPressed: () => context.push(Rutas.evaluar(vm.loteId)),
                        icon: const Icon(PhosphorIconsBold.clipboardText),
                        label: const Text('Evaluar lote'),
                      )
                      : null,
            ),
          ),
        ],
      );
    }
    final calculo = vm.calculoFijacion;
    final editable = vm.editable;
    final clases = vm.clasesCalidad;
    final problema = vm.problemaFijacion;
    return ListView(
      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 120),
      children: [
        if (vm.compra?.fijacion?.syncError != null) ...[
          Aviso(mensaje: vm.compra!.fijacion!.syncError!, tipo: TipoAviso.error),
          const SizedBox(height: GEspacio.m),
        ],
        SeccionTarjeta(
          titulo: 'Evaluación de referencia',
          icono: PhosphorIconsBold.sealCheck,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: vm.evaluacionesCerradas.any((e) => e.id == f.evaluacionId) ? f.evaluacionId : null,
                decoration: const InputDecoration(labelText: 'Evaluación cerrada'),
                items: [
                  for (final e in vm.evaluacionesCerradas)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text('${Formato.fecha(e.fecha)} · ${e.nroMuestras} muestras · ${e.evaluador ?? ''}'),
                    ),
                ],
                onChanged: editable ? (id) => id == null ? null : vm.elegirEvaluacion(id) : null,
              ),
              if (vm.errorEvaluacion != null) ...[
                const SizedBox(height: GEspacio.m),
                Aviso(mensaje: vm.errorEvaluacion!, tipo: TipoAviso.advertencia),
              ],
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Precio base por calidad (S/ por kg)',
          icono: PhosphorIconsBold.tag,
          child: Column(
            children: [
              for (final c in clases)
                Padding(
                  padding: const EdgeInsets.only(bottom: GEspacio.m),
                  child: CampoNumero(
                    etiqueta: c.etiqueta,
                    valor: f.preciosBase[c.id],
                    prefijo: 'S/ ',
                    decimales: 4,
                    habilitado: editable,
                    onChanged: (v) => vm.setPrecioBase(c.id, v),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Precio por muestra',
          icono: PhosphorIconsBold.flask,
          child:
              calculo == null || vm.numerosMuestra.isEmpty
                  ? Text('Sin muestras', style: t.bodySmall)
                  : _TablaMuestras(vm: vm, porMuestra: calculo.precioPorMuestra, promedio: calculo.precioPromedio),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Precio técnico',
          icono: PhosphorIconsBold.calculator,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoNumero(
                etiqueta: 'Gasto de llenado (se resta)',
                valor: f.gastoLlenado == 0 ? null : f.gastoLlenado,
                prefijo: 'S/ ',
                sufijo: '/kg',
                decimales: 4,
                habilitado: editable,
                onChanged: vm.setGastoLlenado,
              ),
              const SizedBox(height: GEspacio.l),
              _Ecuacion(promedio: calculo?.precioPromedio, llenado: f.gastoLlenado, tecnico: calculo?.precioTecnico),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.l),
        SeccionTarjeta(
          titulo: 'Precio pactado con el agricultor',
          icono: PhosphorIconsBold.handshake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Comenta el precio técnico al agricultor o proveedor. Si acuerdan un ajuste, escribe el precio final.',
                style: t.bodySmall,
              ),
              const SizedBox(height: GEspacio.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CampoNumero(
                      etiqueta: 'Precio pactado',
                      valor: f.precioPactado,
                      prefijo: 'S/ ',
                      sufijo: '/kg',
                      decimales: 4,
                      habilitado: editable,
                      onChanged: vm.setPrecioPactado,
                    ),
                  ),
                  const SizedBox(width: GEspacio.m),
                  if (editable)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton(
                        onPressed: (calculo?.precioTecnico ?? 0) > 0 ? vm.usarPrecioTecnico : null,
                        child: const Text('Usar técnico'),
                      ),
                    ),
                ],
              ),
              if (f.precioPactado != null && calculo != null) ...[
                const SizedBox(height: GEspacio.s),
                _Ajuste(ajuste: f.precioPactado! - calculo.precioTecnico),
              ],
            ],
          ),
        ),
        if (editable) ...[
          const SizedBox(height: GEspacio.l),
          if (problema != null) ...[
            Aviso(mensaje: problema, tipo: TipoAviso.advertencia),
            const SizedBox(height: GEspacio.m),
          ],
          ListenableBuilder(
            listenable: vm.guardarFijacion,
            builder:
                (context, _) => Row(
                  children: [
                    if (vm.fijacionModificada && vm.compra?.fijacion != null) ...[
                      TextButton(onPressed: vm.descartarCambiosPrecio, child: const Text('Descartar')),
                      const SizedBox(width: GEspacio.m),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            !vm.fijacionModificada || vm.guardarFijacion.running
                                ? null
                                : () async {
                                  final r = await vm.guardarFijacion.execute();
                                  if (!context.mounted) return;
                                  final mensaje = switch (r) {
                                    Error(:final failure) => failure.message,
                                    _ => f.pactado ? 'Precio pactado guardado' : 'Cálculo guardado',
                                  };
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
                                },
                        icon: const Icon(PhosphorIconsBold.floppyDisk),
                        label: Text(vm.fijacionModificada ? 'Guardar precio' : 'Precio guardado'),
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ],
    );
  }
}

class _TablaMuestras extends StatelessWidget {
  const _TablaMuestras({required this.vm, required this.porMuestra, required this.promedio});

  final CompraViewModel vm;
  final List<double> porMuestra;
  final double promedio;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const num = TextStyle(fontFeatures: GTipo.tabular, fontWeight: FontWeight.w600);
    final clases = vm.clasesCalidad;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        columnSpacing: 22,
        horizontalMargin: 0,
        headingTextStyle: t.labelMedium!.copyWith(color: GColores.tintaSuave),
        columns: [
          const DataColumn(label: Text('')),
          for (final n in vm.numerosMuestra) DataColumn(numeric: true, label: Text('M$n')),
          const DataColumn(
            numeric: true,
            label: Text('PROM', style: TextStyle(color: GColores.primario, fontWeight: FontWeight.w800)),
          ),
        ],
        rows: [
          for (final c in clases)
            DataRow(
              cells: [
                DataCell(Text('% ${c.etiqueta}', style: t.bodySmall)),
                for (final m in vm.calidadMuestras) DataCell(Text(Formato.porcentaje(m[c.id]), style: num)),
                const DataCell(Text('')),
              ],
            ),
          DataRow(
            cells: [
              DataCell(Text('Precio /kg', style: t.titleSmall)),
              for (final p in porMuestra) DataCell(Text(Formato.precioKg(p), style: num)),
              DataCell(
                Text(
                  Formato.precioKg(promedio),
                  style: num.copyWith(color: GColores.primario, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ecuacion extends StatelessWidget {
  const _Ecuacion({required this.promedio, required this.llenado, required this.tecnico});

  final double? promedio;
  final double llenado;
  final double? tecnico;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget bloque(String etiqueta, String valor, {bool fuerte = false}) => Column(
      children: [
        Text(etiqueta, style: t.bodySmall),
        Text(valor, style: GTipo.cifra(fuerte ? 24 : 17, color: fuerte ? GColores.primario : GColores.tinta)),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(GEspacio.m),
      decoration: BoxDecoration(color: GColores.primarioSuave, borderRadius: BorderRadius.circular(GRadio.chico)),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GEspacio.m,
        runSpacing: GEspacio.s,
        children: [
          bloque('Promedio muestras', Formato.precioKg(promedio)),
          Text('−', style: t.titleLarge),
          bloque('Llenado', Formato.precioKg(llenado)),
          Text('=', style: t.titleLarge),
          bloque('Precio técnico /kg', Formato.precioKg(tecnico), fuerte: true),
        ],
      ),
    );
  }
}

class _Ajuste extends StatelessWidget {
  const _Ajuste({required this.ajuste});

  final double ajuste;

  @override
  Widget build(BuildContext context) {
    if (ajuste.abs() < 0.00005) {
      return const Pastilla(texto: 'Igual al precio técnico', color: GColores.exito, icono: PhosphorIconsBold.check);
    }
    final sube = ajuste > 0;
    return Align(
      alignment: Alignment.centerLeft,
      child: Pastilla(
        texto: 'Ajuste ${sube ? '+' : '−'}${Formato.precioKg(ajuste.abs())} /kg sobre el técnico',
        color: sube ? GColores.advertencia : GColores.secundario,
        icono: sube ? PhosphorIconsBold.trendUp : PhosphorIconsBold.trendDown,
      ),
    );
  }
}
