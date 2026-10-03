import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/compra.dart';
import '../../../../../domain/models/sync.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campo_numero.dart';
import '../../../../core/widgets/campos.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/compra_view_model.dart';
import '../widgets/formulario_compra.dart';

/// Gastos vinculados a la materia prima: llevar el producto al packing (estiba, pesaje, flete, otros).
/// No son pagos al agricultor.
class PestanaGastos extends StatelessWidget {
  const PestanaGastos({super.key, required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final compra = vm.compra!;
    final gastos = compra.gastos;
    final b = vm.balance;
    // agrupados: por camión y generales
    final grupos = <String?, List<GastoVinculado>>{};
    for (final g in gastos) {
      grupos.putIfAbsent(compra.numeroCarga(g.cargaId ?? '') > 0 ? g.cargaId : null, () => []).add(g);
    }
    final orden = [...compra.cargas.map((c) => c.id).where(grupos.containsKey), if (grupos.containsKey(null)) null];
    return ListView(
      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 120),
      children: [
        Text(
          'Gastos para llevar la materia prima al packing. No se descuentan del pago al agricultor.',
          style: t.bodySmall,
        ),
        const SizedBox(height: GEspacio.m),
        if (gastos.isEmpty)
          const Card(
            child: EstadoVacio(
              titulo: 'Sin gastos vinculados',
              mensaje: 'Estiba/desestiba, pesaje y flete por cada camión; otros gastos generales del lote.',
            ),
          )
        else ...[
          for (final cargaId in orden)
            SeccionTarjeta(
              titulo: cargaId == null ? 'Generales' : 'Camión ${compra.numeroCarga(cargaId)}',
              icono: cargaId == null ? PhosphorIconsBold.stack : PhosphorIconsBold.truck,
              accion: Text(
                Formato.soles(grupos[cargaId]!.fold<double>(0, (a, g) => a + g.monto)),
                style: GTipo.cifra(14, color: GColores.primario),
              ),
              child: Column(
                children: [
                  for (final g in grupos[cargaId]!)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(vm.buscar(vm.tiposGasto, g.tipoGastoId)?.etiqueta ?? 'Gasto'),
                      subtitle: Text(
                        [Formato.fecha(g.fecha), if ((g.descripcion ?? '').isNotEmpty) g.descripcion!].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (g.syncState != SyncState.sincronizado) EstadoSync(estado: g.syncState, compacto: true),
                          const SizedBox(width: GEspacio.s),
                          Text(Formato.soles(g.monto), style: GTipo.cifra(14)),
                        ],
                      ),
                      onTap:
                          () => abrirFormularioCompra(
                            context,
                            FormularioGasto(vm: vm, gasto: GastoVinculado.fromJson(g.toJson())),
                          ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: GEspacio.m),
          SeccionTarjeta(
            child: Row(
              children: [
                Expanded(child: Text('Total gastos vinculados', style: t.titleMedium)),
                Text(Formato.soles(b.gastosVinculados), style: GTipo.cifra(18, color: GColores.primario)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Formulario de un gasto vinculado.
class FormularioGasto extends StatefulWidget {
  const FormularioGasto({super.key, required this.vm, required this.gasto, this.nuevo = false});

  final CompraViewModel vm;
  final GastoVinculado gasto;
  final bool nuevo;

  @override
  State<FormularioGasto> createState() => _FormularioGastoState();
}

class _FormularioGastoState extends State<FormularioGasto> {
  late final GastoVinculado g = widget.gasto;
  late final _descripcion = TextEditingController(text: g.descripcion);
  final _fotos = FotosNuevas();
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    g.descripcion = _descripcion.text;
    final error = await widget.vm.guardarGasto(g);
    if (error == null) await _fotos.guardar(widget.vm, EntidadComprobante.gasto, g.id);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await confirmarEliminar(context, 'este gasto')) return;
    await widget.vm.eliminarGasto(g);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final editable = vm.editable;
    final tipo = vm.buscar(vm.tiposGasto, g.tipoGastoId);
    final cargas = vm.compra?.cargas ?? const [];
    return MarcoFormulario(
      titulo: widget.nuevo ? 'Nuevo gasto vinculado' : 'Gasto vinculado',
      error: _error,
      guardando: _guardando,
      onGuardar: editable ? _guardar : null,
      onEliminar: editable && !widget.nuevo ? _eliminar : null,
      children: [
        SelectorChips(
          etiqueta: 'Tipo de gasto',
          opciones: vm.tiposGasto,
          seleccion: tipo,
          texto: (e) => e.etiqueta,
          onChanged:
              (e) => setState(() {
                g.tipoGastoId = e.id;
                if (!e.porCarga) g.cargaId = null;
                if (e.porCarga && g.cargaId == null) g.cargaId = cargas.lastOrNull?.id;
              }),
        ),
        DropdownButtonFormField<String?>(
          value: g.cargaId,
          decoration: InputDecoration(
            labelText: 'Camión',
            helperText: tipo?.porCarga ?? false ? 'Este gasto se registra por camión' : null,
          ),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('General del lote')),
            for (final (i, c) in cargas.indexed)
              DropdownMenuItem<String?>(
                value: c.id,
                child: Text('Camión ${i + 1}${c.placa == null ? '' : ' · ${c.placa}'} · ${Formato.kg(c.kg)}'),
              ),
          ],
          onChanged: editable ? (v) => setState(() => g.cargaId = v) : null,
        ),
        Row(
          children: [
            Expanded(
              child: CampoNumero(
                etiqueta: 'Monto',
                valor: g.monto == 0 ? null : g.monto,
                prefijo: 'S/ ',
                habilitado: editable,
                autofocus: widget.nuevo,
                onChanged: (v) => setState(() => g.monto = v ?? 0),
              ),
            ),
            const SizedBox(width: GEspacio.m),
            Expanded(
              child: CampoFecha(
                etiqueta: 'Fecha',
                valor: g.fecha,
                onChanged: (d) => setState(() => g.fecha = d ?? g.fecha),
              ),
            ),
          ],
        ),
        TextField(
          controller: _descripcion,
          enabled: editable,
          maxLength: 250,
          decoration: InputDecoration(
            labelText: tipo?.requiereDescripcion ?? false ? 'Descripción (obligatoria)' : 'Descripción (opcional)',
          ),
        ),
        FotosFormulario(
          vm: vm,
          entidad: EntidadComprobante.gasto,
          entidadId: g.id,
          controlador: _fotos,
          editable: editable,
        ),
      ],
    );
  }
}
