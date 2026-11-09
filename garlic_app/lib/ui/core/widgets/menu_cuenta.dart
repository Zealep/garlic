import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/sesion_repository.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../../routing/rutas.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';

/// Avatar del usuario con su menú: cambiar contraseña, usuarios (administrador) y cerrar sesión.
class MenuCuenta extends StatelessWidget {
  const MenuCuenta({super.key, this.sobreOscuro = false});

  /// Sobre el encabezado verde.
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionRepository>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'Mi cuenta',
      child: InkResponse(
        onTap: () => _abrir(context),
        radius: 26,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: sobreOscuro ? Colors.white : GColores.primarioSuave,
          child: Text(
            usuario.iniciales,
            style: const TextStyle(fontWeight: FontWeight.w800, color: GColores.primario, fontSize: 14),
          ),
        ),
      ),
    );
  }

  static Future<void> _abrir(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      final sesion = context.read<SesionRepository>();
      final u = sesion.usuario!;
      final t = Theme.of(sheet).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GEspacio.l, 0, GEspacio.l, GEspacio.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: GColores.primarioSuave,
                  child: Text(
                    u.iniciales,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: GColores.primario),
                  ),
                ),
                title: Text(u.nombres, style: t.titleMedium),
                subtitle: Text(
                  ['DNI ${u.dni}', if (u.admin) 'Administrador', sesion.sesion?.empresa.razonSocial ?? '']
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.lockKey),
                title: const Text('Cambiar contraseña'),
                onTap: () {
                  Navigator.pop(sheet);
                  context.push(Rutas.clave);
                },
              ),
              if (u.admin)
                ListTile(
                  leading: const Icon(PhosphorIconsRegular.usersThree),
                  title: const Text('Usuarios'),
                  subtitle: const Text('Crear usuarios y asignar contraseñas'),
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push(Rutas.usuarios);
                  },
                ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.signOut, color: GColores.error),
                title: const Text('Cerrar sesión', style: TextStyle(color: GColores.error)),
                onTap: () async {
                  Navigator.pop(sheet);
                  await confirmarCierre(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  /// Pide confirmación; si hay cambios sin enviar, avisa que se conservan y se envían al volver a entrar.
  static Future<void> confirmarCierre(BuildContext context) async {
    final resumen = context.read<SyncRepository>().resumen;
    final pendientes = resumen.pendientes + resumen.errores;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: Text(
              pendientes == 0
                  ? 'Para volver a entrar necesitarás tu DNI, tu contraseña y conexión.'
                  : 'Hay $pendientes cambio${pendientes == 1 ? '' : 's'} sin enviar. Se conservan en este '
                      'dispositivo y se enviarán cuando alguien vuelva a iniciar sesión con conexión.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: GColores.error),
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );
    if (ok == true && context.mounted) await context.read<SesionRepository>().cerrar();
  }
}
