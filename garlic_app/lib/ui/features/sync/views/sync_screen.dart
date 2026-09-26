import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/catalogos_repository.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../data/repositories/sync_repository.dart';
import '../../../../domain/models/sync.dart';
import '../../../../routing/rutas.dart';
import '../../../../utils/formato.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';

/// Centro de sincronización: cola pendiente, errores del servidor y ajustes del dispositivo.
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncRepository>();
    final r = sync.resumen;
    final config = context.watch<ConfigRepository>().config;
    final catalogos = context.watch<CatalogosRepository>();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.s, GEspacio.l, GEspacio.xxxl),
        children: [
          AnchoMaximo(
            max: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Estado(resumen: r, onSincronizar: sync.sincronizar),
                const SizedBox(height: GEspacio.l),
                if (r.errores > 0) ...[
                  Aviso(
                    mensaje:
                        '${r.errores} registro(s) fueron rechazados por el servidor. Revisa el mensaje, corrige y reintenta.',
                    tipo: TipoAviso.error,
                    accion: TextButton(onPressed: sync.reintentarTodo, child: const Text('Reintentar')),
                  ),
                  const SizedBox(height: GEspacio.l),
                ],
                Text('Cola de envío', style: t.titleLarge),
                const SizedBox(height: GEspacio.s),
                StreamBuilder<List<OperacionPendiente>>(
                  stream: sync.observarCola(),
                  builder: (context, snap) {
                    final cola = snap.data ?? const [];
                    if (cola.isEmpty) {
                      return const Card(
                        child: EstadoVacio(
                          titulo: 'Todo enviado',
                          mensaje: 'No hay cambios pendientes en este equipo.',
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final op in cola) ...[
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Icon(
                                op.ultimoError != null
                                    ? PhosphorIconsBold.warningCircle
                                    : PhosphorIconsBold.cloudArrowUp,
                                color: op.ultimoError != null ? GColores.error : GColores.advertencia,
                              ),
                              title: Text(op.descripcion, style: t.titleSmall),
                              subtitle: Text(
                                op.ultimoError ??
                                    '${op.tipo.etiqueta} · ${Formato.relativo(op.creado)}'
                                        '${op.intentos > 0 ? ' · ${op.intentos} intento(s)' : ''}',
                                style:
                                    op.ultimoError != null ? t.bodySmall!.copyWith(color: GColores.error) : t.bodySmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: GEspacio.s),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: GEspacio.xl),
                Text('Este dispositivo', style: t.titleLarge),
                const SizedBox(height: GEspacio.s),
                SeccionTarjeta(
                  child: Column(
                    children: [
                      DatoFila(
                        etiqueta: 'Empresa',
                        valor: config?.empresaNombre ?? '—',
                        icono: PhosphorIconsRegular.buildings,
                      ),
                      DatoFila(
                        etiqueta: 'Evaluador',
                        valor: config?.evaluadorNombre ?? '—',
                        icono: PhosphorIconsRegular.userCircle,
                      ),
                      DatoFila(etiqueta: 'Servidor', valor: config?.apiUrl ?? '—', icono: PhosphorIconsRegular.globe),
                      DatoFila(
                        etiqueta: 'Catálogos',
                        valor: 'Actualizados ${Formato.relativo(catalogos.actualizado)}',
                        icono: PhosphorIconsRegular.books,
                      ),
                      const SizedBox(height: GEspacio.m),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  config == null
                                      ? null
                                      : () async {
                                        final res = await catalogos.descargar(config.cultivoId);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              res.toString().contains('Error')
                                                  ? 'Sin conexión: se usan los catálogos guardados'
                                                  : 'Catálogos actualizados',
                                            ),
                                          ),
                                        );
                                      },
                              icon: const Icon(PhosphorIconsBold.downloadSimple),
                              label: const Text('Actualizar catálogos'),
                            ),
                          ),
                          const SizedBox(width: GEspacio.m),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.go(Rutas.setup),
                              icon: const Icon(PhosphorIconsBold.gear),
                              label: const Text('Reconfigurar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.resumen, required this.onSincronizar});

  final SyncResumen resumen;
  final Future<Object?> Function() onSincronizar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = resumen;
    final (titulo, color, icono) =
        r.errores > 0
            ? ('Hay registros con error', GColores.error, PhosphorIconsFill.warningCircle)
            : !r.online
            ? ('Sin conexión', GColores.advertencia, PhosphorIconsFill.wifiSlash)
            : r.pendientes > 0
            ? ('Cambios por enviar', GColores.advertencia, PhosphorIconsFill.cloudArrowUp)
            : ('Todo al día', GColores.secundario, PhosphorIconsFill.cloudCheck);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GEspacio.xl),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle),
              child: Icon(icono, color: color, size: 30),
            ),
            const SizedBox(width: GEspacio.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: t.titleLarge),
                  Text(
                    '${r.pendientes} pendiente(s) · última sincronización ${Formato.relativo(r.ultimaSincronizacion)}',
                    style: t.bodySmall,
                  ),
                  if (r.ultimoError != null && r.errores == 0)
                    Text(r.ultimoError!, style: t.bodySmall!.copyWith(color: GColores.advertencia)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: r.sincronizando ? null : onSincronizar,
              icon:
                  r.sincronizando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                      : const Icon(PhosphorIconsBold.arrowsClockwise),
              label: const Text('Sincronizar'),
            ),
          ],
        ),
      ),
    );
  }
}
