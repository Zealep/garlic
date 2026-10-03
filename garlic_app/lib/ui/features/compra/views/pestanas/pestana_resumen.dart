import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../utils/formato.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/compra_view_model.dart';
import '../widgets/balance_compra.dart';

/// Resumen del lote: balance de pago, detalle de la compra (3.2 del Excel), gastos vinculados
/// y costos unitarios de la materia prima puesta en packing.
class PestanaResumen extends StatelessWidget {
  const PestanaResumen({super.key, required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final ancho = AnchoVentana.of(context);
    final balance = BalanceCompraPanel(vm: vm);
    final detalle = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Precio(vm: vm),
        const SizedBox(height: GEspacio.l),
        _DetalleCompra(vm: vm),
        const SizedBox(height: GEspacio.l),
        _DetalleGastos(vm: vm),
      ],
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 80),
      children: [
        // en laptop el balance ya está fijo a la derecha de la pantalla
        if (ancho.esExpandido)
          detalle
        else if (ancho.esCompacto) ...[
          balance,
          const SizedBox(height: GEspacio.l),
          detalle,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: detalle),
              const SizedBox(width: GEspacio.xl),
              Expanded(flex: 4, child: balance),
            ],
          ),
      ],
    );
  }
}

class _Precio extends StatelessWidget {
  const _Precio({required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final f = vm.compra?.fijacion;
    final calculo = f?.calcular(vm.calidadMuestras);
    return SeccionTarjeta(
      titulo: 'Precio',
      icono: PhosphorIconsBold.currencyCircleDollar,
      child:
          f == null
              ? Text('Sin fijación de precio', style: Theme.of(context).textTheme.bodySmall)
              : Row(
                children: [
                  Expanded(child: _Mini('Promedio muestras', Formato.precioKg(calculo?.precioPromedio))),
                  Expanded(child: _Mini('Técnico', Formato.precioKg(calculo?.precioTecnico))),
                  Expanded(
                    child: _Mini(
                      'Pactado',
                      f.precioPactado == null ? 'Sin pactar' : Formato.precioKg(f.precioPactado),
                      fuerte: true,
                    ),
                  ),
                ],
              ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.etiqueta, this.valor, {this.fuerte = false});

  final String etiqueta;
  final String valor;
  final bool fuerte;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
      Text(valor, style: GTipo.cifra(fuerte ? 17 : 15, color: fuerte ? GColores.primario : GColores.tinta)),
    ],
  );
}

/// Cuadro "Detalle de la compra · gasto para materia prima": una fila por camión, su destare y el total.
class _DetalleCompra extends StatelessWidget {
  const _DetalleCompra({required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cargas = vm.compra?.cargas ?? const [];
    final b = vm.balance;
    const num = TextStyle(fontFeatures: GTipo.tabular, fontWeight: FontWeight.w600);
    final destare = num.copyWith(color: GColores.advertencia);
    DataCell celda(String v, [TextStyle? s]) => DataCell(Text(v, style: s ?? num));
    return SeccionTarjeta(
      titulo: 'Detalle de la compra · materia prima',
      icono: PhosphorIconsBold.truck,
      child:
          cargas.isEmpty
              ? Text('Sin camiones registrados', style: t.bodySmall)
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 38,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  columnSpacing: 18,
                  horizontalMargin: 0,
                  headingTextStyle: t.labelMedium!.copyWith(color: GColores.tintaSuave),
                  columns: const [
                    DataColumn(label: Text('Concepto')),
                    DataColumn(numeric: true, label: Text('Kg')),
                    DataColumn(numeric: true, label: Text('Empaques')),
                    DataColumn(numeric: true, label: Text('Precio')),
                    DataColumn(numeric: true, label: Text('Total')),
                  ],
                  rows: [
                    for (final (i, c) in cargas.indexed) ...[
                      DataRow(
                        cells: [
                          DataCell(Text('Compra MP · camión ${i + 1}', style: t.bodyMedium)),
                          celda(Formato.kg(c.kg)),
                          celda('${c.cantidadEmpaques}'),
                          celda(Formato.precioKg(c.precioKg)),
                          celda(Formato.soles(c.calculo.importe)),
                        ],
                      ),
                      if (c.calculo.destareKg > 0)
                        DataRow(
                          cells: [
                            DataCell(Text('  Destare ${Formato.porcentaje(c.destarePct)}', style: t.bodySmall)),
                            celda('− ${Formato.kg(c.calculo.destareKg)}', destare),
                            celda(''),
                            celda(Formato.precioKg(c.precioKg), destare),
                            celda('− ${Formato.soles(c.calculo.descuentoDestare)}', destare),
                          ],
                        ),
                    ],
                    DataRow(
                      color: const WidgetStatePropertyAll(GColores.primarioSuave),
                      cells: [
                        DataCell(Text('Pago final al agricultor', style: t.titleSmall)),
                        celda(Formato.kg(b.kgNetos), num.copyWith(fontWeight: FontWeight.w800)),
                        celda('${vm.compra?.cantidadEmpaques ?? 0}'),
                        celda(''),
                        celda(
                          Formato.soles(b.totalMp),
                          num.copyWith(color: GColores.primario, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}

class _DetalleGastos extends StatelessWidget {
  const _DetalleGastos({required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final compra = vm.compra!;
    final b = vm.balance;
    // total por tipo de gasto
    final porTipo = <String, double>{};
    for (final g in compra.gastos) {
      porTipo.update(g.tipoGastoId, (v) => v + g.monto, ifAbsent: () => g.monto);
    }
    return SeccionTarjeta(
      titulo: 'Gastos vinculados a la materia prima',
      icono: PhosphorIconsBold.receipt,
      child: Column(
        children: [
          if (porTipo.isEmpty) Align(alignment: Alignment.centerLeft, child: Text('Sin gastos', style: t.bodySmall)),
          for (final e in porTipo.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(vm.buscar(vm.tiposGasto, e.key)?.etiqueta ?? 'Gasto', style: t.bodyMedium)),
                  Text(Formato.soles(e.value), style: GTipo.cifra(14)),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              Expanded(child: Text('Total · llevar producto a packing', style: t.titleSmall)),
              Text(Formato.soles(b.gastosVinculados), style: GTipo.cifra(15, color: GColores.primario)),
            ],
          ),
        ],
      ),
    );
  }
}
