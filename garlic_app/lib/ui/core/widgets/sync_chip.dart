import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/sync_repository.dart';
import '../../../domain/models/sync.dart';
import '../../../routing/rutas.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';

/// Estado global de sincronización, siempre visible (ui-ux-pro-max: feedback de estado offline).
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, this.compacto = false, this.sobreOscuro = false});

  final bool compacto;
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<SyncRepository>().resumen;
    final (texto, icono, color) = _estado(r);
    final colorTexto = sobreOscuro ? Colors.white : color;
    final contenido =
        r.sincronizando
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorTexto))
            : Icon(icono, size: 18, color: colorTexto);

    return Semantics(
      button: true,
      label: 'Sincronización: $texto',
      child: Material(
        color: sobreOscuro ? Colors.white.withValues(alpha: .14) : color.withValues(alpha: .1),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.go(Rutas.sync),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compacto ? 10 : 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                contenido,
                if (!compacto) ...[
                  const SizedBox(width: GEspacio.s),
                  Text(
                    texto,
                    style: TextStyle(
                      fontFamily: GTipo.texto,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorTexto,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static (String, IconData, Color) _estado(SyncResumen r) {
    if (r.sincronizando) return ('Sincronizando…', PhosphorIconsBold.arrowsClockwise, GColores.info);
    if (r.errores > 0) return ('${r.errores} con error', PhosphorIconsBold.warningCircle, GColores.error);
    if (!r.online) {
      return (
        r.pendientes > 0 ? 'Sin conexión · ${r.pendientes}' : 'Sin conexión',
        PhosphorIconsBold.wifiSlash,
        GColores.advertencia,
      );
    }
    if (r.pendientes > 0) return ('${r.pendientes} por enviar', PhosphorIconsBold.cloudArrowUp, GColores.advertencia);
    return ('Al día', PhosphorIconsBold.cloudCheck, GColores.secundario);
  }
}
