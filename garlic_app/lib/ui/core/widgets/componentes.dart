import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/sync.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';
import 'marca.dart';

/// Tarjeta de sección con título opcional.
class SeccionTarjeta extends StatelessWidget {
  const SeccionTarjeta({super.key, this.titulo, this.icono, this.accion, required this.child, this.padding});

  final String? titulo;
  final IconData? icono;
  final Widget? accion;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(GEspacio.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titulo != null) ...[
              Row(
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 20, color: GColores.primario),
                    const SizedBox(width: GEspacio.s),
                  ],
                  Expanded(child: Text(titulo!, style: t.titleMedium)),
                  if (accion != null) accion!,
                ],
              ),
              const SizedBox(height: GEspacio.m),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Indicador numérico del dashboard.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color = GColores.primario,
    this.fondo = GColores.primarioSuave,
    this.detalle,
    this.onTap,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final Color fondo;
  final String? detalle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GEspacio.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(10)),
                child: Icon(icono, size: 20, color: color),
              ),
              const SizedBox(height: GEspacio.m),
              Text(valor, style: GTipo.cifra(30, color: GColores.tinta)),
              const SizedBox(height: 2),
              Text(titulo, style: t.labelMedium!.copyWith(color: GColores.tintaSuave)),
              if (detalle != null) ...[
                const SizedBox(height: 2),
                Text(detalle!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta en forma de píldora.
class Pastilla extends StatelessWidget {
  const Pastilla({super.key, required this.texto, this.color = GColores.primario, this.fondo, this.icono});

  final String texto;
  final Color color;
  final Color? fondo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: fondo ?? color.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icono != null) ...[Icon(icono, size: 14, color: color), const SizedBox(width: 4)],
        Text(texto, style: TextStyle(fontFamily: GTipo.texto, fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
}

/// Estado de sincronización de un registro: punto de color + texto (nunca solo color).
class EstadoSync extends StatelessWidget {
  const EstadoSync({super.key, required this.estado, this.compacto = false});

  final SyncState estado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final (texto, icono) = switch (estado) {
      SyncState.sincronizado => ('Sincronizado', PhosphorIconsBold.cloudCheck),
      SyncState.pendiente => ('Pendiente', PhosphorIconsBold.cloudArrowUp),
      SyncState.error => ('Con error', PhosphorIconsBold.warningCircle),
    };
    final color = GColores.sync(estado);
    if (compacto) {
      return Tooltip(message: texto, child: Icon(icono, size: 18, color: color, semanticLabel: texto));
    }
    return Pastilla(texto: texto, color: color, icono: icono);
  }
}

/// Estado vacío con el sello de marca.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.titulo, required this.mensaje, this.accion});

  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GEspacio.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(color: GColores.superficieAlt, shape: BoxShape.circle),
                child: const GarlicMark(size: 56),
              ),
              const SizedBox(height: GEspacio.l),
              Text(titulo, style: t.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: GEspacio.s),
              Text(mensaje, style: t.bodyMedium!.copyWith(color: GColores.tintaSuave), textAlign: TextAlign.center),
              if (accion != null) ...[const SizedBox(height: GEspacio.xl), accion!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila "etiqueta · valor" para fichas de detalle.
class DatoFila extends StatelessWidget {
  const DatoFila({super.key, required this.etiqueta, required this.valor, this.icono});

  final String etiqueta;
  final String valor;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[Icon(icono, size: 18, color: GColores.tintaSuave), const SizedBox(width: GEspacio.m)],
          Expanded(flex: 2, child: Text(etiqueta, style: t.bodyMedium!.copyWith(color: GColores.tintaSuave))),
          Expanded(flex: 3, child: Text(valor, style: t.bodyMedium!.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Banner de aviso (offline, errores de validación, etc.).
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.mensaje, this.tipo = TipoAviso.info, this.accion});

  final String mensaje;
  final TipoAviso tipo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final (color, fondo, icono) = switch (tipo) {
      TipoAviso.info => (GColores.info, const Color(0xFFE3EEF7), PhosphorIconsBold.info),
      TipoAviso.advertencia => (GColores.advertencia, GColores.advertenciaSuave, PhosphorIconsBold.warning),
      TipoAviso.error => (GColores.error, GColores.errorSuave, PhosphorIconsBold.warningCircle),
      TipoAviso.exito => (GColores.exito, GColores.exitoSuave, PhosphorIconsBold.checkCircle),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(GRadio.chico),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: GEspacio.m),
            Expanded(
              child: Text(mensaje, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: GColores.tinta)),
            ),
            if (accion != null) accion!,
          ],
        ),
      ),
    );
  }
}

enum TipoAviso { info, advertencia, error, exito }

/// Versión sliver de [AnchoMaximo]: centra listas/grillas con ancho máximo en pantallas grandes.
class SliverAnchoMaximo extends StatelessWidget {
  const SliverAnchoMaximo({super.key, required this.sliver, this.max = 1180, this.abajo = 110});

  final Widget sliver;
  final double max;
  final double abajo;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, c) {
      final lateral = c.crossAxisExtent > max ? (c.crossAxisExtent - max) / 2 + GEspacio.l : GEspacio.l;
      return SliverPadding(padding: EdgeInsets.fromLTRB(lateral, 0, lateral, abajo), sliver: sliver);
    },
  );
}

/// Limita el ancho del contenido en pantallas grandes (flutter-build-responsive-layout).
class AnchoMaximo extends StatelessWidget {
  const AnchoMaximo({super.key, required this.child, this.max = 1180});

  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    // heightFactor 1: toma el alto del hijo (no se expande dentro de barras o columnas)
    heightFactor: 1,
    child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child),
  );
}
