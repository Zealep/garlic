import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/lote.dart';
import '../../../../routing/rutas.dart';
import '../../../../utils/formato.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/evaluacion_tile.dart';
import '../../../core/widgets/marca.dart';
import '../../compra/views/widgets/balance_compra.dart';
import '../view_models/lotes_view_model.dart';

class LoteDetalleScreen extends StatelessWidget {
  const LoteDetalleScreen({super.key, required this.viewModel});

  final LoteDetalleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final lote = viewModel.lote;
        if (lote == null) {
          return Scaffold(
            appBar: AppBar(),
            body:
                viewModel.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : const EstadoVacio(titulo: 'Lote no encontrado', mensaje: 'Actualiza la lista de lotes.'),
          );
        }
        final ancho = AnchoVentana.of(context);
        final borrador = viewModel.borradorAbierto;
        final ficha = _Ficha(lote: lote);
        final historial = _Historial(vm: viewModel, lote: lote);
        return Scaffold(
          floatingActionButton:
              lote.activo
                  ? FloatingActionButton.extended(
                    onPressed:
                        () => context.push(
                          borrador == null ? Rutas.evaluar(lote.id) : Rutas.evaluacion(lote.id, borrador.id),
                        ),
                    icon: Icon(borrador == null ? PhosphorIconsBold.clipboardText : PhosphorIconsBold.pencilSimpleLine),
                    label: Text(borrador == null ? 'Evaluar lote' : 'Continuar borrador'),
                  )
                  : null,
          body: RefreshIndicator(
            onRefresh: () => viewModel.refrescar.execute(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Cabecera(lote: lote)),
                SliverToBoxAdapter(
                  child: AnchoMaximo(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.xl, GEspacio.l, 110),
                      child:
                          ancho.esCompacto
                              ? Column(children: [ficha, const SizedBox(height: GEspacio.xl), historial])
                              : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: ficha),
                                  const SizedBox(width: GEspacio.xl),
                                  Expanded(flex: 6, child: historial),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.lote});

  final Lote lote;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FondoMarca(
      child: SafeArea(
        bottom: false,
        child: AnchoMaximo(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(GEspacio.s, GEspacio.s, GEspacio.xl, GEspacio.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Volver',
                  onPressed: () => context.canPop() ? context.pop() : context.go(Rutas.lotes),
                  icon: const Icon(PhosphorIconsBold.arrowLeft, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: GEspacio.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Zona ${lote.zona}', style: t.labelLarge!.copyWith(color: GColores.acento)),
                            Text(lote.codigo, style: t.displaySmall!.copyWith(color: Colors.white)),
                            const SizedBox(height: GEspacio.s),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _PastillaClara(PhosphorIconsFill.leaf, lote.variedad.texto),
                                _PastillaClara(
                                  PhosphorIconsFill.calendarBlank,
                                  'Campaña ${lote.campania.codigo ?? ''}',
                                ),
                                _PastillaClara(PhosphorIconsFill.tag, lote.tipoCompra.texto),
                                if (!lote.activo) const _PastillaClara(PhosphorIconsFill.prohibit, 'Anulado'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const GarlicMark(size: 64, claro: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PastillaClara extends StatelessWidget {
  const _PastillaClara(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: GColores.acento),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.lote});

  final Lote lote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lote.syncState.name != 'sincronizado') ...[
          Aviso(
            mensaje: lote.syncError ?? 'Guardado en el equipo. Se enviará al servidor cuando haya conexión.',
            tipo: lote.syncError == null ? TipoAviso.advertencia : TipoAviso.error,
          ),
          const SizedBox(height: GEspacio.m),
        ],
        SeccionTarjeta(
          titulo: 'Identificación',
          icono: PhosphorIconsBold.identificationCard,
          child: Column(
            children: [
              DatoFila(etiqueta: 'Agricultor', valor: lote.agricultor.nombres, icono: PhosphorIconsRegular.user),
              DatoFila(etiqueta: 'Proveedor', valor: lote.proveedor?.nombres ?? '—', icono: PhosphorIconsRegular.truck),
              DatoFila(
                etiqueta: 'DNI liquidación',
                valor:
                    lote.titularLiquidacion == null
                        ? '—'
                        : '${lote.titularLiquidacion!.numeroDocumento ?? ''} · ${lote.titularLiquidacion!.nombres}',
                icono: PhosphorIconsRegular.receipt,
              ),
              DatoFila(etiqueta: 'Localidad', valor: lote.localidad.texto, icono: PhosphorIconsRegular.mapTrifold),
              DatoFila(
                etiqueta: 'Ubicación',
                valor:
                    lote.tieneUbicacion
                        ? '${lote.latitud!.toStringAsFixed(5)}, ${lote.longitud!.toStringAsFixed(5)}'
                        : 'Sin coordenadas',
                icono: PhosphorIconsRegular.crosshair,
              ),
            ],
          ),
        ),
        const SizedBox(height: GEspacio.m),
        SeccionTarjeta(
          titulo: 'Fechas',
          icono: PhosphorIconsBold.calendarDots,
          child: Row(
            children: [
              _Fecha('Arrancado', lote.fechaArrancado),
              _Fecha('Corte', lote.fechaCorte),
              _Fecha('Carga', lote.fechaCarga),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fecha extends StatelessWidget {
  const _Fecha(this.etiqueta, this.fecha);

  final String etiqueta;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: t.bodySmall),
          const SizedBox(height: 2),
          Text(Formato.fechaCorta(fecha), style: t.titleSmall),
        ],
      ),
    );
  }
}

class _Historial extends StatelessWidget {
  const _Historial({required this.vm, required this.lote});

  final LoteDetalleViewModel vm;
  final Lote lote;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResumenCompraTarjeta(
          compra: vm.compra,
          editable: lote.activo,
          onTap: () => context.push(Rutas.compra(lote.id)),
        ),
        const SizedBox(height: GEspacio.xl),
        Text('Evaluaciones de calidad', style: t.titleLarge),
        const SizedBox(height: GEspacio.m),
        if (vm.evaluaciones.isEmpty)
          const Card(
            child: EstadoVacio(
              titulo: 'Sin evaluaciones',
              mensaje: 'Toma las muestras representativas y registra calidad, calibre, humedad y sanidad.',
            ),
          )
        else
          for (final e in vm.evaluaciones) ...[
            EvaluacionTile(
              evaluacion: e,
              mostrarLote: false,
              onTap: () => context.push(Rutas.evaluacion(lote.id, e.id)),
            ),
            const SizedBox(height: GEspacio.s),
          ],
      ],
    );
  }
}
