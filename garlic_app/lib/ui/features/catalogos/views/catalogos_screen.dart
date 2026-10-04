import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/definicion_catalogo.dart';
import '../../../../utils/formato.dart';
import '../../../../utils/result.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/campos.dart';
import '../../../core/widgets/componentes.dart';
import '../view_models/catalogos_view_model.dart';

IconData _icono(GrupoCatalogo g) => switch (g) {
  GrupoCatalogo.lote => PhosphorIconsBold.plant,
  GrupoCatalogo.calidad => PhosphorIconsBold.sealPercent,
  GrupoCatalogo.compra => PhosphorIconsBold.handCoins,
};

/// Catálogos de la empresa: lista de catálogos y el detalle del elegido (lado a lado en tablet/laptop).
class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key, required this.viewModel});

  final CatalogosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.cargar]),
      builder: (context, _) {
        final vm = viewModel;
        final compacto = AnchoVentana.of(context).esCompacto;
        final lista = _ListaCatalogos(vm: vm);
        if (compacto) {
          return PopScope(
            canPop: vm.seleccionado == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) vm.seleccionar(null);
            },
            child:
                vm.seleccionado == null
                    ? Scaffold(appBar: AppBar(title: const Text('Catálogos')), body: lista)
                    : _Detalle(vm: vm, conVolver: true),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Catálogos')),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 320, child: lista),
              const VerticalDivider(width: 1),
              Expanded(
                child:
                    vm.seleccionado == null
                        ? const EstadoVacio(
                          titulo: 'Elige un catálogo',
                          mensaje: 'Agrega o edita las opciones que usan los formularios de la empresa.',
                        )
                        : _Detalle(vm: vm),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListaCatalogos extends StatelessWidget {
  const _ListaCatalogos({required this.vm});

  final CatalogosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: GEspacio.m),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(GEspacio.l, 0, GEspacio.l, GEspacio.m),
          child: Text(
            'Las opciones se configuran por empresa. Requiere conexión; los cambios se descargan solos al equipo.',
            style: t.bodySmall,
          ),
        ),
        for (final g in GrupoCatalogo.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.m, GEspacio.l, GEspacio.xs),
            child: Row(
              children: [
                Icon(_icono(g), size: 16, color: GColores.primario),
                const SizedBox(width: GEspacio.s),
                Text(g.titulo, style: t.labelLarge!.copyWith(color: GColores.primario)),
              ],
            ),
          ),
          for (final d in DefinicionCatalogo.todas.where((d) => d.grupo == g))
            ListTile(
              selected: vm.seleccionado == d,
              selectedTileColor: GColores.primarioSuave,
              title: Text(d.titulo),
              trailing: const Icon(PhosphorIconsBold.caretRight, size: 18),
              onTap: () => vm.seleccionar(d),
            ),
        ],
      ],
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({required this.vm, this.conVolver = false});

  final CatalogosViewModel vm;
  final bool conVolver;

  Future<void> _abrir(BuildContext context, Map<String, Object?>? item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder:
        (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: _Formulario(vm: vm, item: item),
        ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = vm.seleccionado!;
    final items = vm.visibles;
    final error = vm.cargar.failure;
    return Scaffold(
      appBar:
          conVolver
              ? AppBar(
                leading: IconButton(
                  icon: const Icon(PhosphorIconsBold.arrowLeft),
                  onPressed: () => vm.seleccionar(null),
                ),
                title: Text(d.titulo),
              )
              : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(context, null),
        icon: const Icon(PhosphorIconsBold.plus),
        label: const Text('Nuevo'),
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.cargar.execute(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 110),
          children: [
            if (!conVolver) Text(d.titulo, style: t.titleLarge),
            Text(d.descripcion, style: t.bodySmall),
            const SizedBox(height: GEspacio.m),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por código o nombre',
                      prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                      isDense: true,
                    ),
                    onChanged: vm.setFiltro,
                  ),
                ),
                if (vm.inactivos > 0) ...[
                  const SizedBox(width: GEspacio.m),
                  FilterChip(
                    label: Text('Inactivos (${vm.inactivos})'),
                    selected: vm.mostrarInactivos,
                    onSelected: (_) => vm.alternarInactivos(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: GEspacio.m),
            if (error != null)
              Aviso(
                mensaje:
                    error.kind == FailureKind.sinConexion
                        ? 'Sin conexión: los catálogos se administran en línea.'
                        : error.message,
                tipo: TipoAviso.error,
                accion: TextButton(onPressed: () => vm.cargar.execute(), child: const Text('Reintentar')),
              )
            else if (vm.cargar.running && vm.items.isEmpty)
              const Padding(padding: EdgeInsets.all(GEspacio.xxl), child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              const Card(child: EstadoVacio(titulo: 'Sin registros', mensaje: 'Agrega la primera opción con "Nuevo".'))
            else
              Card(
                child: Column(
                  children: [
                    for (final (i, item) in items.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _Fila(vm: vm, item: item, onTap: () => _abrir(context, item)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.vm, required this.item, required this.onTap});

  final CatalogosViewModel vm;
  final Map<String, Object?> item;
  final VoidCallback onTap;

  /// Datos propios del catálogo para el subtítulo (rango, peso, banderas…).
  String _detalle(DefinicionCatalogo d) {
    final partes = <String>[];
    if (item['nombre'] != null && item['codigo'] != null && item['codigo'] != item['nombre']) {
      partes.add('${item['codigo']}');
    }
    for (final c in d.campos) {
      final v = item[c.clave];
      if (c.clave == 'codigo' || c.clave == 'nombre' || c.clave == 'orden' || v == null) continue;
      switch (c.tipo) {
        case TipoCampo.booleano:
          if (v == true) partes.add(c.etiqueta);
        case TipoCampo.fecha:
          partes.add('${c.etiqueta} ${Formato.fecha(Formato.parseFecha(v))}');
        case TipoCampo.opcion:
          partes.add(c.opciones[v] ?? '$v');
        case TipoCampo.decimal || TipoCampo.entero:
          partes.add('${c.etiqueta.replaceAll(RegExp(r' \(.*\)'), '')}: $v');
        case TipoCampo.texto:
          partes.add('$v');
      }
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final d = vm.seleccionado!;
    final activo = item['activo'] != false;
    final detalle = _detalle(d);
    return ListTile(
      onTap: onTap,
      leading:
          d.ordenable
              ? CircleAvatar(
                radius: 16,
                backgroundColor: activo ? GColores.primarioSuave : GColores.superficieAlt,
                child: Text(
                  '${item['orden'] ?? ''}',
                  style: TextStyle(
                    color: activo ? GColores.primario : GColores.tintaSuave,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              )
              : null,
      title: Text(
        d.etiquetaDe(item),
        style: TextStyle(
          color: activo ? null : GColores.tintaSuave,
          decoration: activo ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: detalle.isEmpty ? null : Text(detalle),
      trailing: Tooltip(
        message: activo ? 'Activo (aparece en los formularios)' : 'Inactivo',
        child: Switch(
          value: activo,
          onChanged: (v) async {
            final r = await vm.cambiarActivo(item, activo: v);
            if (r case Error(:final failure) when context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
            }
          },
        ),
      ),
    );
  }
}

/// Formulario genérico a partir de los campos de la definición.
class _Formulario extends StatefulWidget {
  const _Formulario({required this.vm, required this.item});

  final CatalogosViewModel vm;
  final Map<String, Object?>? item;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final Map<String, Object?> _valores = widget.vm.valoresIniciales(widget.item);
  late final Map<String, TextEditingController> _textos = {
    for (final c in widget.vm.seleccionado!.campos)
      if (c.tipo case TipoCampo.texto || TipoCampo.entero || TipoCampo.decimal)
        c.clave: TextEditingController(text: _valores[c.clave] == null ? '' : '${_valores[c.clave]}'),
  };
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in _textos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    for (final c in widget.vm.seleccionado!.campos) {
      final ctrl = _textos[c.clave];
      if (ctrl == null) continue;
      final t = ctrl.text.trim();
      _valores[c.clave] = switch (c.tipo) {
        TipoCampo.entero => int.tryParse(t),
        TipoCampo.decimal => double.tryParse(t.replaceAll(',', '.')),
        _ => t.isEmpty ? null : (c.mayusculas ? t.toUpperCase() : t),
      };
    }
    setState(() => _guardando = true);
    final r = await widget.vm.guardar(_valores, id: widget.item?['id'] as String?);
    if (!mounted) return;
    switch (r) {
      case Ok():
        Navigator.pop(context);
      case Error(:final failure):
        setState(() {
          _guardando = false;
          _error =
              failure.fieldErrors.isEmpty
                  ? failure.message
                  : failure.fieldErrors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        });
    }
  }

  Widget _campo(CampoCatalogo c) => switch (c.tipo) {
    TipoCampo.booleano => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(c.etiqueta),
      subtitle: c.ayuda == null ? null : Text(c.ayuda!),
      value: _valores[c.clave] == true,
      onChanged: (v) => setState(() => _valores[c.clave] = v),
    ),
    TipoCampo.fecha => CampoFecha(
      etiqueta: c.etiqueta,
      valor: Formato.parseFecha(_valores[c.clave]),
      onChanged: (d) => setState(() => _valores[c.clave] = d == null ? null : Formato.fechaIso(d)),
    ),
    TipoCampo.opcion => SelectorChips<String>(
      etiqueta: c.etiqueta,
      opciones: c.opciones.keys.toList(),
      seleccion: _valores[c.clave] as String?,
      texto: (k) => c.opciones[k]!,
      onChanged: (k) => setState(() => _valores[c.clave] = k),
    ),
    _ => TextField(
      controller: _textos[c.clave],
      maxLength: c.max,
      textCapitalization: c.mayusculas ? TextCapitalization.characters : TextCapitalization.sentences,
      keyboardType:
          c.tipo == TipoCampo.texto
              ? TextInputType.text
              : TextInputType.numberWithOptions(decimal: c.tipo == TipoCampo.decimal),
      inputFormatters: [
        if (c.tipo == TipoCampo.entero) FilteringTextInputFormatter.digitsOnly,
        if (c.tipo == TipoCampo.decimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,2})?')),
      ],
      decoration: InputDecoration(labelText: c.requerido ? '${c.etiqueta} *' : c.etiqueta, helperText: c.ayuda),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = widget.vm.seleccionado!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(GEspacio.xl, 0, GEspacio.xl, GEspacio.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.item == null ? 'Nuevo' : 'Editar'} · ${d.titulo}', style: t.titleLarge),
          if (widget.item != null && d.campos.any((c) => c.clave == 'codigo'))
            Padding(
              padding: const EdgeInsets.only(top: GEspacio.xs),
              child: Text(
                'Los registros ya usados conservan este catálogo aunque cambies el nombre.',
                style: t.bodySmall,
              ),
            ),
          const SizedBox(height: GEspacio.l),
          for (final c in d.campos) ...[_campo(c), const SizedBox(height: GEspacio.m)],
          if (_error != null) ...[
            Text(_error!, style: t.bodyMedium!.copyWith(color: GColores.error, fontWeight: FontWeight.w600)),
            const SizedBox(height: GEspacio.m),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon:
                  _guardando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(PhosphorIconsBold.floppyDisk),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
