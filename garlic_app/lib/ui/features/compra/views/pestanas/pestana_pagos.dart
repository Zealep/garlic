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
import '../widgets/balance_compra.dart';
import '../widgets/formulario_compra.dart';

/// 3.1 Abonos / adelantos al agricultor o proveedor, solo por la materia prima.
class PestanaPagos extends StatelessWidget {
  const PestanaPagos({super.key, required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pagos = vm.compra?.pagos ?? const [];
    final b = vm.balance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 120),
      children: [
        SeccionTarjeta(
          child: Row(
            children: [
              Expanded(child: _Dato('Total materia prima', Formato.soles(b.totalMp))),
              Expanded(child: _Dato('Pagado', Formato.soles(b.totalPagado))),
              Expanded(child: _Dato('Saldo', Formato.soles(b.saldo), color: colorEstadoPago(b.estadoPago))),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.m),
        Text('Solo pagos por la materia prima. Los gastos de llevarla al packing van en Gastos.', style: t.bodySmall),
        const SizedBox(height: GEspacio.m),
        if (pagos.isEmpty)
          const Card(
            child: EstadoVacio(
              titulo: 'Sin pagos',
              mensaje: 'Registra cada abono o adelanto con su condición (cuenta, efectivo, crédito) y el voucher.',
            ),
          )
        else
          for (final p in pagos) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: GColores.secundarioSuave,
                  child: Icon(PhosphorIconsBold.money, color: GColores.secundario),
                ),
                title: Text(Formato.soles(p.monto), style: GTipo.cifra(16)),
                subtitle: Text(
                  [
                    Formato.fecha(p.fecha),
                    vm.buscar(vm.condicionesPago, p.condicionPagoId)?.etiqueta ?? '',
                    if (p.beneficiarioId != null)
                      vm.beneficiarios.where((x) => x.personaId == p.beneficiarioId).firstOrNull?.nombre ?? '',
                    if ((p.referencia ?? '').isNotEmpty) 'Op. ${p.referencia}',
                  ].where((s) => s.isNotEmpty).join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.fotosDe(p.id).isNotEmpty)
                      const Icon(PhosphorIconsBold.camera, size: 18, color: GColores.tintaSuave),
                    if (p.syncState != SyncState.sincronizado) ...[
                      const SizedBox(width: GEspacio.s),
                      EstadoSync(estado: p.syncState, compacto: true),
                    ],
                  ],
                ),
                onTap: () => abrirFormularioCompra(context, FormularioPago(vm: vm, pago: Pago.fromJson(p.toJson()))),
              ),
            ),
            if (p.syncError != null)
              Padding(
                padding: const EdgeInsets.only(left: GEspacio.l, bottom: GEspacio.s),
                child: Text(p.syncError!, style: t.bodySmall!.copyWith(color: GColores.error)),
              ),
            const SizedBox(height: GEspacio.s),
          ],
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor, {this.color = GColores.tinta});

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(valor, style: GTipo.cifra(16, color: color)),
      ),
    ],
  );
}

/// Formulario de un pago.
class FormularioPago extends StatefulWidget {
  const FormularioPago({super.key, required this.vm, required this.pago, this.nuevo = false});

  final CompraViewModel vm;
  final Pago pago;
  final bool nuevo;

  @override
  State<FormularioPago> createState() => _FormularioPagoState();
}

class _FormularioPagoState extends State<FormularioPago> {
  late final Pago p = widget.pago;
  late final _referencia = TextEditingController(text: p.referencia);
  late final _observacion = TextEditingController(text: p.observacion);
  final _fotos = FotosNuevas();
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _referencia.dispose();
    _observacion.dispose();
    super.dispose();
  }

  /// Saldo pendiente sin contar este pago (para "Pagar saldo").
  double get _saldoSinEste {
    final actual = widget.vm.compra?.pagos.where((x) => x.id == p.id).firstOrNull?.monto ?? 0;
    return widget.vm.balance.saldo + actual;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    p
      ..referencia = _referencia.text
      ..observacion = _observacion.text;
    final error = await widget.vm.guardarPago(p);
    if (error == null) await _fotos.guardar(widget.vm, EntidadComprobante.pago, p.id);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await confirmarEliminar(context, 'este pago')) return;
    await widget.vm.eliminarPago(p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final editable = vm.editable;
    final saldo = _saldoSinEste;
    final beneficiarios = vm.beneficiarios;
    return MarcoFormulario(
      titulo: widget.nuevo ? 'Nuevo pago' : 'Pago',
      error: _error,
      guardando: _guardando,
      onGuardar: editable ? _guardar : null,
      onEliminar: editable && !widget.nuevo ? _eliminar : null,
      children: [
        SelectorChips(
          etiqueta: 'Condición',
          opciones: vm.condicionesPago,
          seleccion: vm.buscar(vm.condicionesPago, p.condicionPagoId),
          texto: (e) => e.etiqueta,
          onChanged: (e) => setState(() => p.condicionPagoId = e.id),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoNumero(
                etiqueta: 'Monto',
                valor: p.monto == 0 ? null : p.monto,
                prefijo: 'S/ ',
                habilitado: editable,
                autofocus: widget.nuevo,
                onChanged: (v) => setState(() => p.monto = v ?? 0),
              ),
            ),
            const SizedBox(width: GEspacio.m),
            Expanded(
              child: CampoFecha(
                etiqueta: 'Fecha',
                valor: p.fecha,
                onChanged: (d) => setState(() => p.fecha = d ?? p.fecha),
              ),
            ),
          ],
        ),
        if (editable && saldo > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(PhosphorIconsBold.checks, size: 16),
              label: Text('Pagar saldo ${Formato.soles(saldo)}'),
              onPressed: () => setState(() => p.monto = saldo),
            ),
          ),
        if (beneficiarios.isNotEmpty)
          DropdownButtonFormField<String?>(
            value: beneficiarios.any((b) => b.personaId == p.beneficiarioId) ? p.beneficiarioId : null,
            decoration: const InputDecoration(labelText: 'Beneficiario'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Sin indicar')),
              for (final b in beneficiarios)
                DropdownMenuItem<String?>(value: b.personaId, child: Text('${b.nombre} · ${b.rol}')),
            ],
            onChanged: editable ? (v) => setState(() => p.beneficiarioId = v) : null,
          ),
        TextField(
          controller: _referencia,
          enabled: editable,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'N.º de operación (opcional)'),
        ),
        TextField(
          controller: _observacion,
          enabled: editable,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Observación (opcional)'),
        ),
        FotosFormulario(
          vm: vm,
          entidad: EntidadComprobante.pago,
          entidadId: p.id,
          controlador: _fotos,
          editable: editable,
        ),
      ],
    );
  }
}
