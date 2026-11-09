import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../data/repositories/usuarios_repository.dart';
import '../../../../utils/formato.dart';
import '../../../../utils/result.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../view_models/usuarios_view_model.dart';

/// Usuarios de la empresa (solo administrador): alta con contraseña temporal, nueva contraseña temporal
/// (olvido) y desactivar. Requiere conexión.
class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key, required this.viewModel});

  final UsuariosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevo(context),
        icon: const Icon(PhosphorIconsBold.userPlus),
        label: const Text('Nuevo usuario'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.cargar]),
        builder: (context, _) {
          if (vm.cargar.running && vm.lista.isEmpty) return const Center(child: CircularProgressIndicator());
          if (vm.cargar.failure case final f? when vm.lista.isEmpty) {
            return EstadoVacio(
              titulo: 'No se pudo cargar',
              mensaje: '${f.message}. La gestión de usuarios necesita conexión.',
              accion: OutlinedButton(onPressed: vm.cargar.execute, child: const Text('Reintentar')),
            );
          }
          return RefreshIndicator(
            onRefresh: vm.cargar.execute,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, 110),
              children: [
                AnchoMaximo(
                  max: 760,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Aviso(
                        mensaje:
                            'Cada persona entra con su DNI. Al crearla le asignas una contraseña temporal '
                            'y en su primer ingreso la cambia por una propia.',
                        tipo: TipoAviso.info,
                      ),
                      const SizedBox(height: GEspacio.l),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, u) in vm.lista.indexed) ...[
                              if (i > 0) const Divider(height: 1),
                              _FilaUsuario(usuario: u, esYo: u.id == vm.miId, vm: vm),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _nuevo(BuildContext context) async {
    final datos = await showDialog<_DatosUsuario>(context: context, builder: (_) => const _DialogoUsuario());
    if (datos == null || !context.mounted) return;
    final r = await viewModel.crear(
      nombres: datos.nombres,
      dni: datos.dni,
      email: datos.email,
      admin: datos.admin,
      claveTemporal: datos.clave!,
    );
    if (!context.mounted) return;
    switch (r) {
      case Ok(:final value):
        await _mostrarCredenciales(context, value, datos.clave!);
      case Error(:final failure):
        _avisar(context, failure.message);
    }
  }
}

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({required this.usuario, required this.esYo, required this.vm});

  final UsuarioItem usuario;
  final bool esYo;
  final UsuariosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = usuario;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: GEspacio.l, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: u.activo ? GColores.primarioSuave : GColores.superficieAlt,
        child: Text(
          u.nombres.isEmpty ? '?' : u.nombres[0].toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w700, color: u.activo ? GColores.primario : GColores.tintaSuave),
        ),
      ),
      title: Text(u.nombres + (esYo ? ' (tú)' : ''), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('DNI ${u.dni}', style: t.bodySmall),
            if (u.admin) const Pastilla(texto: 'Administrador', color: GColores.primario),
            if (!u.activo) const Pastilla(texto: 'Inactivo', color: GColores.tintaSuave),
            if (u.activo && !u.tieneClave) const Pastilla(texto: 'Sin contraseña', color: GColores.advertencia),
            Text(
              u.ultimoAcceso == null ? 'Nunca entró' : 'Último ingreso ${Formato.relativo(u.ultimoAcceso)}',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Acciones',
        icon: const Icon(PhosphorIconsBold.dotsThreeVertical),
        onSelected: (accion) => _accion(context, accion),
        itemBuilder:
            (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar datos')),
              if (u.activo) const PopupMenuItem(value: 'clave', child: Text('Asignar contraseña temporal')),
              if (!esYo) PopupMenuItem(value: 'activo', child: Text(u.activo ? 'Desactivar' : 'Activar')),
            ],
      ),
    );
  }

  Future<void> _accion(BuildContext context, String accion) async {
    switch (accion) {
      case 'editar':
        final datos = await showDialog<_DatosUsuario>(
          context: context,
          builder: (_) => _DialogoUsuario(existente: usuario),
        );
        if (datos == null || !context.mounted) return;
        final r = await vm.actualizar(usuario, nombres: datos.nombres, email: datos.email, admin: datos.admin);
        if (r case Error(:final failure) when context.mounted) _avisar(context, failure.message);
      case 'clave':
        final clave = UsuariosViewModel.claveTemporal();
        final ok = await showDialog<bool>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: const Text('Asignar contraseña temporal'),
                content: Text(
                  'Se cerrarán las sesiones abiertas de ${usuario.nombres} y deberá entrar con una contraseña '
                  'temporal nueva, que cambiará en su primer ingreso.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                  FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Asignar')),
                ],
              ),
        );
        if (ok != true || !context.mounted) return;
        final r = await vm.asignarClave(usuario, clave);
        if (!context.mounted) return;
        switch (r) {
          case Ok(:final value):
            await _mostrarCredenciales(context, value, clave);
          case Error(:final failure):
            _avisar(context, failure.message);
        }
      case 'activo':
        final r = await vm.cambiarActivo(usuario);
        if (r case Error(:final failure) when context.mounted) _avisar(context, failure.message);
    }
  }
}

void _avisar(BuildContext context, String mensaje) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

/// Muestra el DNI y la contraseña temporal para entregarlos a la persona (solo se ven una vez).
Future<void> _mostrarCredenciales(BuildContext context, UsuarioItem u, String clave) {
  final texto = 'Ingreso a Guadalupe · Compra de ajo\nDNI: ${u.dni}\nContraseña temporal: $clave';
  return showDialog<void>(
    context: context,
    builder: (c) {
      final t = Theme.of(c).textTheme;
      return AlertDialog(
        icon: const Icon(PhosphorIconsBold.key, color: GColores.primario),
        title: const Text('Entrega estos datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.nombres, style: t.titleMedium),
            const SizedBox(height: GEspacio.m),
            DatoFila(etiqueta: 'DNI', valor: u.dni, icono: PhosphorIconsRegular.identificationCard),
            DatoFila(etiqueta: 'Contraseña temporal', valor: clave, icono: PhosphorIconsRegular.lockKey),
            const SizedBox(height: GEspacio.m),
            Text(
              'Anótala ahora: no se vuelve a mostrar. Al entrar, el sistema le pedirá crear su propia contraseña.',
              style: t.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: texto));
              if (c.mounted) _avisar(c, 'Copiado');
            },
            icon: const Icon(PhosphorIconsBold.copy),
            label: const Text('Copiar'),
          ),
          FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Listo')),
        ],
      );
    },
  );
}

class _DatosUsuario {
  const _DatosUsuario({required this.nombres, required this.dni, this.email, required this.admin, this.clave});

  final String nombres;
  final String dni;
  final String? email;
  final bool admin;
  final String? clave;
}

/// Alta (con contraseña temporal sugerida) o edición de datos (el DNI no cambia: es con lo que entra).
class _DialogoUsuario extends StatefulWidget {
  const _DialogoUsuario({this.existente});

  final UsuarioItem? existente;

  @override
  State<_DialogoUsuario> createState() => _DialogoUsuarioState();
}

class _DialogoUsuarioState extends State<_DialogoUsuario> {
  final _formKey = GlobalKey<FormState>();
  late final _nombres = TextEditingController(text: widget.existente?.nombres ?? '');
  late final _dni = TextEditingController(text: widget.existente?.dni ?? '');
  late final _email = TextEditingController(text: widget.existente?.email ?? '');
  late final _clave = TextEditingController(text: UsuariosViewModel.claveTemporal());
  late bool _admin = widget.existente?.admin ?? false;

  bool get _nuevo => widget.existente == null;

  @override
  void dispose() {
    _nombres.dispose();
    _dni.dispose();
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_nuevo ? 'Nuevo usuario' : 'Editar usuario'),
    scrollable: true,
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombres,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombres y apellidos'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: GEspacio.m),
            TextFormField(
              controller: _dni,
              enabled: _nuevo,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              decoration: InputDecoration(
                labelText: 'DNI',
                helperText: _nuevo ? 'Con este DNI entra al sistema' : 'El DNI no se cambia',
              ),
              validator: (v) => (v ?? '').length != 8 ? 'El DNI tiene 8 dígitos' : null,
            ),
            const SizedBox(height: GEspacio.m),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo (opcional)'),
              validator: (v) {
                final s = (v ?? '').trim();
                return s.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Correo inválido';
              },
            ),
            if (_nuevo) ...[
              const SizedBox(height: GEspacio.m),
              TextFormField(
                controller: _clave,
                decoration: InputDecoration(
                  labelText: 'Contraseña temporal',
                  helperText: 'La cambiará en su primer ingreso',
                  suffixIcon: IconButton(
                    tooltip: 'Generar otra',
                    icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                    onPressed: () => setState(() => _clave.text = UsuariosViewModel.claveTemporal()),
                  ),
                ),
                validator: (v) => (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null,
              ),
            ],
            const SizedBox(height: GEspacio.s),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _admin,
              onChanged: (v) => setState(() => _admin = v),
              title: const Text('Administrador'),
              subtitle: const Text('Puede crear usuarios y asignar contraseñas'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _DatosUsuario(
              nombres: _nombres.text,
              dni: _dni.text,
              email: _email.text,
              admin: _admin,
              clave: _nuevo ? _clave.text : null,
            ),
          );
        },
        child: Text(_nuevo ? 'Crear' : 'Guardar'),
      ),
    ],
  );
}
