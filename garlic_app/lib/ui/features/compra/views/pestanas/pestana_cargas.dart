import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/compra.dart';
import '../../../../../domain/models/sync.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campo_numero.dart';
import '../../../../core/widgets/campo_porcentaje.dart';
import '../../../../core/widgets/campos.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/compra_view_model.dart';
import '../widgets/formulario_compra.dart';

/// 3.2 Compra de materia prima: un registro por camión (kg, empaques, precio, destare).
class PestanaCargas extends StatelessWidget {
  const PestanaCargas({super.key, required this.vm});

  final CompraViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cargas = vm.compra?.cargas ?? const [];
    final b = vm.balance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 120),
      children: [
        if (vm.precioPactado == null && vm.editable) ...[
          Aviso(
            mensaje: 'Aún no hay precio pactado: el precio por kg de cada camión se escribe a mano.',
            tipo: TipoAviso.info,
            accion: TextButton(onPressed: () => vm.irA(PestanaCompra.precio), child: const Text('Fijar precio')),
          ),
          const SizedBox(height: GEspacio.m),
        ],
        if (cargas.isEmpty)
          const Card(
            child: EstadoVacio(
              titulo: 'Sin camiones',
              mensaje: 'Registra cada camión por separado: kg del ticket de balanza, empaques y destare.',
            ),
          )
        else ...[
          for (final (i, c) in cargas.indexed) ...[
            _TarjetaCarga(vm: vm, carga: c, numero: i + 1),
            const SizedBox(height: GEspacio.s),
          ],
          const SizedBox(height: GEspacio.s),
          SeccionTarjeta(
            child: Column(
              children: [
                _Total('Kg cargados', Formato.kg(b.kgCargados)),
                _Total('Destare', '− ${Formato.kg(b.destareKg)}'),
                _Total('Kg netos', Formato.kg(b.kgNetos)),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: Text('Pago final al agricultor', style: t.titleMedium)),
                    Text(Formato.soles(b.totalMp), style: GTipo.cifra(18, color: GColores.primario)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium)),
        Text(valor, style: GTipo.cifra(14)),
      ],
    ),
  );
}

class _TarjetaCarga extends StatelessWidget {
  const _TarjetaCarga({required this.vm, required this.carga, required this.numero});

  final CompraViewModel vm;
  final Carga carga;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = carga.calculo;
    final empaque = vm.buscar(vm.tiposEmpaque, carga.tipoEmpaqueId)?.etiqueta ?? 'empaques';
    final fotos = vm.fotosDe(carga.id).length;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(GRadio.tarjeta),
        onTap: () => abrirFormularioCompra(context, FormularioCarga(vm: vm, carga: Carga.fromJson(carga.toJson()))),
        child: Padding(
          padding: const EdgeInsets.all(GEspacio.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: GColores.primarioSuave,
                    child: Text('$numero', style: t.titleSmall!.copyWith(color: GColores.primario)),
                  ),
                  const SizedBox(width: GEspacio.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Camión $numero${carga.placa == null ? '' : ' · ${carga.placa}'}', style: t.titleMedium),
                        Text(Formato.fecha(carga.fecha), style: t.bodySmall),
                      ],
                    ),
                  ),
                  if (carga.syncState != SyncState.sincronizado) EstadoSync(estado: carga.syncState, compacto: true),
                  const SizedBox(width: GEspacio.s),
                  Text(Formato.soles(l.total), style: GTipo.cifra(16, color: GColores.primario)),
                ],
              ),
              const SizedBox(height: GEspacio.m),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Pastilla(
                    texto: Formato.kg(carga.kg),
                    icono: PhosphorIconsBold.scales,
                    color: GColores.tinta,
                    fondo: GColores.superficieAlt,
                  ),
                  Pastilla(
                    texto: '$empaque: ${carga.cantidadEmpaques}',
                    color: GColores.tinta,
                    fondo: GColores.superficieAlt,
                  ),
                  Pastilla(
                    texto: '${Formato.precioKg(carga.precioKg)}/kg',
                    color: GColores.tinta,
                    fondo: GColores.superficieAlt,
                  ),
                  Pastilla(
                    texto: 'Destare ${Formato.porcentaje(carga.destarePct)} (${Formato.kg(l.destareKg)})',
                    color: GColores.advertencia,
                  ),
                  if (fotos > 0)
                    Pastilla(texto: '$fotos foto${fotos == 1 ? '' : 's'}', icono: PhosphorIconsBold.camera),
                ],
              ),
              if (carga.syncError != null) ...[
                const SizedBox(height: GEspacio.s),
                Text(carga.syncError!, style: t.bodySmall!.copyWith(color: GColores.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Formulario de un camión.
class FormularioCarga extends StatefulWidget {
  const FormularioCarga({super.key, required this.vm, required this.carga, this.nueva = false});

  final CompraViewModel vm;
  final Carga carga;
  final bool nueva;

  @override
  State<FormularioCarga> createState() => _FormularioCargaState();
}

class _FormularioCargaState extends State<FormularioCarga> {
  late final Carga c = widget.carga;
  final _fotos = FotosNuevas();
  late final _placa = TextEditingController(text: c.placa);
  String? _error;
  bool _guardando = false;
  bool _empaquesTocados = false;

  @override
  void initState() {
    super.initState();
    _empaquesTocados = !widget.nueva;
  }

  @override
  void dispose() {
    _placa.dispose();
    super.dispose();
  }

  /// Sugiere la cantidad de empaques con el peso referencial del tipo (ej. malla de 40 kg).
  void _sugerirEmpaques() {
    final peso = widget.vm.buscar(widget.vm.tiposEmpaque, c.tipoEmpaqueId)?.pesoReferencialKg;
    if (_empaquesTocados || peso == null || c.kg <= 0) return;
    c.cantidadEmpaques = (c.kg / peso).round();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    c.placa = _placa.text;
    final error = await widget.vm.guardarCarga(c);
    if (error == null) await _fotos.guardar(widget.vm, EntidadComprobante.carga, c.id);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    if (!await confirmarEliminar(context, 'este camión')) return;
    final error = await widget.vm.eliminarCarga(c);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final editable = vm.editable;
    final l = c.calculo;
    final t = Theme.of(context).textTheme;
    return MarcoFormulario(
      titulo: widget.nueva ? 'Nuevo camión' : 'Camión',
      error: _error,
      guardando: _guardando,
      onGuardar: editable ? _guardar : null,
      onEliminar: editable && !widget.nueva ? _eliminar : null,
      children: [
        Row(
          children: [
            Expanded(
              child: CampoFecha(
                etiqueta: 'Fecha de carga',
                valor: c.fecha,
                onChanged: (d) => setState(() => c.fecha = d ?? c.fecha),
              ),
            ),
            const SizedBox(width: GEspacio.m),
            Expanded(
              child: TextField(
                controller: _placa,
                enabled: editable,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Placa (opcional)'),
              ),
            ),
          ],
        ),
        CampoNumero(
          etiqueta: 'Kg cargados (ticket de balanza)',
          valor: c.kg == 0 ? null : c.kg,
          sufijo: 'kg',
          habilitado: editable,
          autofocus: widget.nueva,
          onChanged:
              (v) => setState(() {
                c.kg = v ?? 0;
                _sugerirEmpaques();
              }),
        ),
        if (vm.tiposEmpaque.isNotEmpty)
          SelectorChips(
            etiqueta: 'Empaque',
            opciones: vm.tiposEmpaque,
            seleccion: vm.buscar(vm.tiposEmpaque, c.tipoEmpaqueId),
            texto: (e) => e.etiqueta,
            onChanged:
                (e) => setState(() {
                  c.tipoEmpaqueId = e.id;
                  _sugerirEmpaques();
                }),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoNumero(
                etiqueta: 'Cantidad de empaques',
                valor: c.cantidadEmpaques.toDouble(),
                entero: true,
                habilitado: editable,
                onChanged:
                    (v) => setState(() {
                      _empaquesTocados = true;
                      c.cantidadEmpaques = v?.toInt() ?? 0;
                    }),
              ),
            ),
            const SizedBox(width: GEspacio.m),
            Expanded(
              child: CampoPorcentaje(
                etiqueta: 'Destare',
                valor: c.destarePct,
                habilitado: editable,
                onChanged: (v) => setState(() => c.destarePct = v ?? 0),
              ),
            ),
          ],
        ),
        CampoNumero(
          etiqueta: 'Precio por kg',
          valor: c.precioKg == 0 ? null : c.precioKg,
          prefijo: 'S/ ',
          decimales: 4,
          habilitado: editable,
          ayuda: vm.precioPactado == null ? null : 'Pactado: ${Formato.precioKg(vm.precioPactado)}',
          onChanged: (v) => setState(() => c.precioKg = v ?? 0),
        ),
        Container(
          padding: const EdgeInsets.all(GEspacio.m),
          decoration: BoxDecoration(color: GColores.primarioSuave, borderRadius: BorderRadius.circular(GRadio.chico)),
          child: Column(
            children: [
              _LineaCalculo(
                'Importe (${Formato.kg(c.kg)} × ${Formato.precioKg(c.precioKg)})',
                Formato.soles(l.importe),
              ),
              _LineaCalculo('Destare (${Formato.kg(l.destareKg)})', '− ${Formato.soles(l.descuentoDestare)}'),
              const Divider(),
              Row(
                children: [
                  Expanded(child: Text('Total del camión', style: t.titleSmall)),
                  Text(Formato.soles(l.total), style: GTipo.cifra(18, color: GColores.primario)),
                ],
              ),
            ],
          ),
        ),
        FotosFormulario(
          vm: vm,
          entidad: EntidadComprobante.carga,
          entidadId: c.id,
          controlador: _fotos,
          editable: editable,
        ),
      ],
    );
  }
}

class _LineaCalculo extends StatelessWidget {
  const _LineaCalculo(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(etiqueta, style: Theme.of(context).textTheme.bodySmall)),
        Text(valor, style: GTipo.cifra(14)),
      ],
    ),
  );
}
