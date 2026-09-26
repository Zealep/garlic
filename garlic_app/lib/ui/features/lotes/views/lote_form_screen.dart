import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/catalogo.dart';
import '../../../../domain/models/lote.dart';
import '../../../../routing/rutas.dart';
import '../../../../utils/result.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/campos.dart';
import '../../../core/widgets/componentes.dart';
import '../view_models/lote_form_view_model.dart';

class LoteFormScreen extends StatefulWidget {
  const LoteFormScreen({super.key, required this.viewModel});

  final LoteFormViewModel viewModel;

  @override
  State<LoteFormScreen> createState() => _LoteFormScreenState();
}

class _LoteFormScreenState extends State<LoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _intentado = false;

  LoteFormViewModel get vm => widget.viewModel;

  Future<void> _guardar() async {
    setState(() => _intentado = true);
    final valido = _formKey.currentState!.validate() && vm.variedadId != null;
    if (!valido) return;
    final r = await vm.guardar.execute();
    if (!mounted) return;
    if (r case Ok<Lote>(:final value)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lote ${value.codigo} guardado. Se sincronizará automáticamente.')));
      context.pushReplacement(Rutas.lote(value.id));
    } else {
      _formKey.currentState!.validate(); // muestra el error del servidor/local en su campo
    }
  }

  Future<void> _nuevoAgricultor() async {
    final datos = await showDialog<({String dni, String nombres})>(
      context: context,
      builder: (_) => const _DialogoPersona(),
    );
    if (datos == null) return;
    final r = await vm.registrarAgricultor.execute(datos);
    if (!mounted) return;
    if (r case Error(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo lote'),
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(PhosphorIconsBold.x),
          onPressed: () => context.canPop() ? context.pop() : context.go(Rutas.lotes),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.guardar, vm.ubicar, vm.registrarAgricultor]),
        builder:
            (context, _) => Form(
              key: _formKey,
              autovalidateMode: _intentado ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GEspacio.l, 0, GEspacio.l, 120),
                children: [
                  AnchoMaximo(
                    max: 720,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _campos(context)),
                  ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.s, GEspacio.l, GEspacio.m),
          child: AnchoMaximo(
            max: 720,
            child: ListenableBuilder(
              listenable: vm.guardar,
              builder:
                  (context, _) => SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: vm.guardar.running ? null : _guardar,
                      icon: const Icon(PhosphorIconsBold.floppyDisk),
                      label: const Text('Guardar lote'),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _campos(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final failure = vm.guardar.failure;
    return [
      if (failure != null && failure.fieldErrors.isEmpty) ...[
        const SizedBox(height: GEspacio.m),
        Aviso(mensaje: failure.message, tipo: TipoAviso.error),
      ],
      const TituloGrupo(
        'Lote',
        subtitulo: 'Código y zona identifican el lote en la campaña',
        icono: PhosphorIconsBold.plant,
      ),
      _Desplegable<CatalogoItem>(
        etiqueta: 'Campaña',
        icono: PhosphorIconsRegular.calendarCheck,
        opciones: vm.campanias,
        valor: vm.campaniaId,
        id: (c) => c.id,
        texto: (c) => c.codigo,
        onChanged: (v) => vm.cambiar(() => vm.campaniaId = v),
      ),
      const SizedBox(height: GEspacio.l),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              initialValue: vm.codigo,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Código', hintText: 'LOTE 008'),
              onChanged: (v) => vm.codigo = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el código' : null,
            ),
          ),
          const SizedBox(width: GEspacio.m),
          Expanded(
            child: TextFormField(
              initialValue: vm.zona,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Zona',
                hintText: 'B3 P52',
                helperText: 'No se repite en la campaña',
                errorText: vm.errorCampo('zona'),
              ),
              onChanged: (v) {
                vm.zona = v;
                if (vm.errorCampo('zona') != null) vm.guardar.clearResult();
              },
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese la zona' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: GEspacio.l),
      SelectorChips<CatalogoItem>(
        etiqueta: 'Variedad',
        opciones: vm.variedades,
        seleccion: vm.variedades.where((v) => v.id == vm.variedadId).firstOrNull,
        texto: (v) => v.etiqueta,
        onChanged: (v) => vm.cambiar(() => vm.variedadId = v.id),
        error: _intentado && vm.variedadId == null ? 'Seleccione la variedad' : null,
      ),
      const SizedBox(height: GEspacio.l),
      _Desplegable<CatalogoItem>(
        etiqueta: 'Tipo de compra',
        icono: PhosphorIconsRegular.tag,
        opciones: vm.tiposCompra,
        valor: vm.tipoCompraId,
        id: (c) => c.id,
        texto: (c) => c.etiqueta,
        onChanged: (v) => vm.cambiar(() => vm.tipoCompraId = v),
      ),
      const TituloGrupo('Personas', subtitulo: 'Agricultor, proveedor y liquidación', icono: PhosphorIconsBold.users),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Desplegable<PersonaItem>(
              etiqueta: 'Agricultor',
              icono: PhosphorIconsRegular.user,
              opciones: vm.agricultores,
              valor: vm.agricultorId,
              id: (p) => p.id,
              texto: (p) => '${p.nombreVisible}${p.documento == null ? '' : ' · ${p.documento}'}',
              onChanged: (v) => vm.cambiar(() => vm.agricultorId = v),
            ),
          ),
          const SizedBox(width: GEspacio.s),
          SizedBox(
            height: 56,
            child: IconButton.filledTonal(
              tooltip: 'Registrar agricultor',
              onPressed: vm.registrarAgricultor.running ? null : _nuevoAgricultor,
              icon:
                  vm.registrarAgricultor.running
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(PhosphorIconsBold.userPlus),
            ),
          ),
        ],
      ),
      const SizedBox(height: GEspacio.l),
      _Desplegable<PersonaItem>(
        etiqueta: 'Proveedor (opcional)',
        icono: PhosphorIconsRegular.truck,
        opciones: vm.proveedores,
        valor: vm.proveedorId,
        id: (p) => p.id,
        texto: (p) => p.nombreVisible,
        requerido: false,
        onChanged: (v) => vm.cambiar(() => vm.proveedorId = v),
      ),
      const SizedBox(height: GEspacio.s),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: vm.titularDistinto,
        onChanged: (v) => vm.cambiar(() => vm.titularDistinto = v),
        title: Text('Liquidación a nombre de otra persona', style: t.titleSmall),
        subtitle: const Text('DNI LC distinto al del agricultor'),
      ),
      if (vm.titularDistinto) ...[
        const SizedBox(height: GEspacio.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: vm.titularDni,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(labelText: 'DNI LC', counterText: ''),
                onChanged: (v) => vm.titularDni = v,
                validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '') ? null : 'DNI de 8 dígitos',
              ),
            ),
            const SizedBox(width: GEspacio.m),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: vm.titularNombres,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombres'),
                onChanged: (v) => vm.titularNombres = v,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese los nombres' : null,
              ),
            ),
          ],
        ),
      ],
      const TituloGrupo('Ubicación', subtitulo: 'Localidad y punto GPS del campo', icono: PhosphorIconsBold.mapPin),
      _Desplegable<CatalogoItem>(
        etiqueta: 'Ciudad / CCPP',
        icono: PhosphorIconsRegular.mapTrifold,
        opciones: vm.localidades,
        valor: vm.localidadId,
        id: (c) => c.id,
        texto: (c) => c.etiqueta,
        onChanged: (v) => vm.cambiar(() => vm.localidadId = v),
      ),
      const SizedBox(height: GEspacio.m),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(
            vm.latitud == null ? PhosphorIconsRegular.crosshair : PhosphorIconsFill.mapPinLine,
            color: vm.latitud == null ? GColores.tintaSuave : GColores.secundario,
          ),
          title: Text(
            vm.latitud == null
                ? 'Sin coordenadas'
                : '${vm.latitud!.toStringAsFixed(5)}, ${vm.longitud!.toStringAsFixed(5)}',
          ),
          subtitle:
              vm.ubicar.failure == null
                  ? const Text('Usa el GPS del teléfono en el campo')
                  : Text(vm.ubicar.failure!.message),
          trailing: TextButton(
            onPressed: vm.ubicar.running ? null : () => vm.ubicar.execute(),
            child: Text(vm.ubicar.running ? 'Ubicando…' : 'Usar mi ubicación'),
          ),
        ),
      ),
      const TituloGrupo(
        'Fechas',
        subtitulo: 'Arrancado, corte y carga del lote',
        icono: PhosphorIconsBold.calendarDots,
      ),
      LayoutBuilder(
        builder: (context, c) {
          final campos = [
            CampoFecha(
              etiqueta: 'Arrancado',
              valor: vm.fechaArrancado,
              onChanged: (d) => vm.cambiar(() => vm.fechaArrancado = d),
            ),
            CampoFecha(etiqueta: 'Corte', valor: vm.fechaCorte, onChanged: (d) => vm.cambiar(() => vm.fechaCorte = d)),
            CampoFecha(etiqueta: 'Carga', valor: vm.fechaCarga, onChanged: (d) => vm.cambiar(() => vm.fechaCarga = d)),
          ];
          if (c.maxWidth < 560) {
            return Column(
              children: [for (final f in campos) Padding(padding: const EdgeInsets.only(bottom: 12), child: f)],
            );
          }
          return Row(
            children: [
              for (final (i, f) in campos.indexed) ...[
                if (i > 0) const SizedBox(width: GEspacio.m),
                Expanded(child: f),
              ],
            ],
          );
        },
      ),
    ];
  }
}

class _Desplegable<T> extends StatelessWidget {
  const _Desplegable({
    required this.etiqueta,
    required this.icono,
    required this.opciones,
    required this.valor,
    required this.id,
    required this.texto,
    required this.onChanged,
    this.requerido = true,
  });

  final String etiqueta;
  final IconData icono;
  final List<T> opciones;
  final String? valor;
  final String Function(T) id;
  final String Function(T) texto;
  final ValueChanged<String?> onChanged;
  final bool requerido;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: opciones.any((o) => id(o) == valor) ? valor : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: etiqueta, prefixIcon: Icon(icono)),
    items: [
      if (!requerido) const DropdownMenuItem<String>(child: Text('— Ninguno —')),
      for (final o in opciones) DropdownMenuItem(value: id(o), child: Text(texto(o), overflow: TextOverflow.ellipsis)),
    ],
    onChanged: onChanged,
    validator: requerido ? (v) => v == null ? 'Seleccione ${etiqueta.toLowerCase()}' : null : null,
  );
}

class _DialogoPersona extends StatefulWidget {
  const _DialogoPersona();

  @override
  State<_DialogoPersona> createState() => _DialogoPersonaState();
}

class _DialogoPersonaState extends State<_DialogoPersona> {
  final _key = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _nombres = TextEditingController();

  @override
  void dispose() {
    _dni.dispose();
    _nombres.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar agricultor'),
    content: Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _dni,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: const InputDecoration(labelText: 'DNI', counterText: ''),
            validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '') ? null : 'DNI de 8 dígitos',
          ),
          const SizedBox(height: GEspacio.m),
          TextFormField(
            controller: _nombres,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombres y apellidos'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese los nombres' : null,
          ),
          const SizedBox(height: GEspacio.m),
          const Aviso(mensaje: 'Requiere conexión. Si el DNI ya existe se reutiliza la persona.'),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (_key.currentState!.validate()) {
            Navigator.pop(context, (dni: _dni.text.trim(), nombres: _nombres.text.trim()));
          }
        },
        child: const Text('Registrar'),
      ),
    ],
  );
}
