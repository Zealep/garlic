import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/use_cases/reglas_evaluacion.dart';
import '../../../../routing/rutas.dart';
import '../../../../utils/formato.dart';
import '../../../../utils/result.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../view_models/evaluacion_view_model.dart';
import 'pasos/paso_general.dart';
import 'pasos/paso_muestras.dart';
import 'pasos/paso_resumen.dart';
import 'pasos/paso_sanidad.dart';
import 'pasos/paso_sensoriales.dart';

/// Wizard de evaluación. Celular: pasos arriba y botones abajo.
/// Tablet/laptop: pasos a la izquierda, formulario al centro y resumen en vivo a la derecha.
class EvaluacionScreen extends StatelessWidget {
  const EvaluacionScreen({super.key, required this.viewModel});

  final EvaluacionViewModel viewModel;

  Future<void> _salir(BuildContext context) async {
    await viewModel.guardarAhora();
    if (!context.mounted) return;
    context.canPop() ? context.pop() : context.go(Rutas.lote(viewModel.loteId));
  }

  Future<void> _cerrar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(PhosphorIconsBold.sealCheck, color: GColores.secundario, size: 32),
            title: const Text('¿Cerrar la evaluación?'),
            content: const Text('Ya no se podrá modificar. Se enviará al servidor en cuanto haya conexión.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Seguir editando')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar evaluación')),
            ],
          ),
    );
    if (ok != true) return;
    final r = await viewModel.cerrar.execute();
    if (!context.mounted) return;
    final mensaje = switch (r) {
      Error(:final failure) => failure.message,
      _ => 'Evaluación cerrada. Se sincronizará automáticamente.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.cargar, viewModel.cerrar]),
      builder: (context, _) {
        final vm = viewModel;
        if (!vm.listo) {
          return Scaffold(
            appBar: AppBar(),
            body:
                vm.cargar.failure != null
                    ? EstadoVacio(titulo: 'No se pudo abrir', mensaje: vm.cargar.failure!.message)
                    : const Center(child: CircularProgressIndicator()),
          );
        }
        final ancho = AnchoVentana.of(context);
        final contenido = _ContenidoPaso(vm: vm);
        return PopScope(
          onPopInvokedWithResult: (_, __) => vm.guardarAhora(),
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Guardar y salir',
                icon: const Icon(PhosphorIconsBold.arrowLeft),
                onPressed: () => _salir(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evaluación · ${vm.lote!.codigo}'),
                  Text(
                    'Zona ${vm.lote!.zona} · ${vm.lote!.variedad.texto}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [_EstadoGuardado(vm: vm), const SizedBox(width: GEspacio.m)],
              bottom:
                  ancho.esCompacto
                      ? PreferredSize(preferredSize: const Size.fromHeight(64), child: _PasosHorizontal(vm: vm))
                      : null,
            ),
            body:
                ancho.esCompacto
                    ? contenido
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: ancho.esExpandido ? 250 : 210, child: _PasosVertical(vm: vm)),
                        const VerticalDivider(width: 1),
                        Expanded(child: contenido),
                        if (ancho.esExpandido) ...[
                          const VerticalDivider(width: 1),
                          SizedBox(width: 340, child: ResumenEnVivo(vm: vm)),
                        ],
                      ],
                    ),
            bottomNavigationBar: _BarraAcciones(vm: vm, onCerrar: () => _cerrar(context)),
          ),
        );
      },
    );
  }
}

class _ContenidoPaso extends StatelessWidget {
  const _ContenidoPaso({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final paso = switch (vm.paso) {
      PasoEvaluacion.general => PasoGeneral(vm: vm),
      PasoEvaluacion.muestras => PasoMuestras(vm: vm),
      PasoEvaluacion.sensoriales => PasoSensoriales(vm: vm),
      PasoEvaluacion.sanidad => PasoSanidad(vm: vm),
      PasoEvaluacion.resumen => PasoResumen(vm: vm),
    };
    // Cambio de paso instantáneo: en formularios largos un fundido distrae y retrasa al evaluador.
    return KeyedSubtree(
      key: ValueKey(vm.paso),
      child: ListView(
        key: ValueKey(vm.paso),
        padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.l, GEspacio.l, GEspacio.xxxl),
        children: [
          AnchoMaximo(
            max: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!vm.editable) ...[
                  const Aviso(mensaje: 'Evaluación cerrada: solo lectura.', tipo: TipoAviso.exito),
                  const SizedBox(height: GEspacio.l),
                ],
                IgnorePointer(ignoring: !vm.editable && vm.paso != PasoEvaluacion.resumen, child: paso),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoGuardado extends StatelessWidget {
  const _EstadoGuardado({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (vm.guardando) {
      return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (vm.ultimoGuardado == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'Guardado en el equipo; se sincroniza solo',
      child: Row(
        children: [
          const Icon(PhosphorIconsBold.checkCircle, size: 16, color: GColores.secundario),
          const SizedBox(width: 4),
          Text('Guardado', style: t.labelMedium!.copyWith(color: GColores.secundario)),
        ],
      ),
    );
  }
}

class _PasosHorizontal extends StatelessWidget {
  const _PasosHorizontal({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(GEspacio.l, 8, GEspacio.l, 12),
        itemCount: PasoEvaluacion.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final p = PasoEvaluacion.values[i];
          return _ChipPaso(
            paso: p,
            indice: i,
            actual: vm.paso == p,
            completo: vm.pasoCompleto(p),
            onTap: () => vm.irA(p),
          );
        },
      ),
    );
  }
}

class _ChipPaso extends StatelessWidget {
  const _ChipPaso({
    required this.paso,
    required this.indice,
    required this.actual,
    required this.completo,
    required this.onTap,
  });

  final PasoEvaluacion paso;
  final int indice;
  final bool actual;
  final bool completo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fondo = actual ? GColores.primario : (completo ? GColores.secundarioSuave : GColores.superficie);
    final texto = actual ? Colors.white : (completo ? GColores.secundario : GColores.tintaSuave);
    return Semantics(
      selected: actual,
      button: true,
      label: 'Paso ${indice + 1}: ${paso.titulo}${completo ? ', completo' : ''}',
      child: Material(
        color: fondo,
        shape: StadiumBorder(side: BorderSide(color: actual ? GColores.primario : GColores.borde)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (completo && !actual)
                  Icon(PhosphorIconsBold.check, size: 15, color: texto)
                else
                  Text(
                    '${indice + 1}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: texto, fontFeatures: GTipo.tabular),
                  ),
                const SizedBox(width: 6),
                Text(paso.titulo, style: TextStyle(fontWeight: FontWeight.w600, color: texto, fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasosVertical extends StatelessWidget {
  const _PasosVertical({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final completos = PasoEvaluacion.values.where(vm.pasoCompleto).length;
    return ListView(
      padding: const EdgeInsets.all(GEspacio.m),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Text('Progreso', style: t.labelMedium!.copyWith(color: GColores.tintaSuave)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completos / PasoEvaluacion.values.length,
              minHeight: 6,
              backgroundColor: GColores.superficieAlt,
              color: GColores.secundario,
            ),
          ),
        ),
        const SizedBox(height: GEspacio.m),
        for (final (i, p) in PasoEvaluacion.values.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              selected: vm.paso == p,
              selectedTileColor: GColores.primarioSuave,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadio.chico)),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor:
                    vm.pasoCompleto(p)
                        ? GColores.secundario
                        : (vm.paso == p ? GColores.primario : GColores.superficieAlt),
                child:
                    vm.pasoCompleto(p)
                        ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white)
                        : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: vm.paso == p ? Colors.white : GColores.tintaSuave,
                          ),
                        ),
              ),
              title: Text(p.titulo, style: t.titleSmall!.copyWith(color: vm.paso == p ? GColores.primario : null)),
              onTap: () => vm.irA(p),
            ),
          ),
      ],
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({required this.vm, required this.onCerrar});

  final EvaluacionViewModel vm;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final ultimo = vm.paso == PasoEvaluacion.resumen;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: GColores.superficie,
        border: Border(top: BorderSide(color: GColores.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GEspacio.l, GEspacio.m, GEspacio.l, GEspacio.m),
          child: AnchoMaximo(
            max: 760,
            child: Row(
              children: [
                if (vm.paso.index > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: vm.anterior,
                      icon: const Icon(PhosphorIconsBold.arrowLeft),
                      label: const Text('Anterior'),
                    ),
                  ),
                if (vm.paso.index > 0) const SizedBox(width: GEspacio.m),
                Expanded(
                  flex: 2,
                  child:
                      ultimo
                          ? (vm.editable
                              ? FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: GColores.secundario),
                                onPressed: vm.cerrar.running ? null : onCerrar,
                                icon: const Icon(PhosphorIconsBold.sealCheck),
                                label: const Text('Cerrar evaluación'),
                              )
                              : FilledButton.icon(
                                onPressed: () => context.canPop() ? context.pop() : context.go(Rutas.inicio),
                                icon: const Icon(PhosphorIconsBold.check),
                                label: const Text('Listo'),
                              ))
                          : FilledButton.icon(
                            onPressed: vm.siguiente,
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(PhosphorIconsBold.arrowRight),
                            label: Text('Siguiente: ${PasoEvaluacion.values[vm.paso.index + 1].titulo}'),
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

/// Panel derecho en laptop: promedios y pendientes en vivo mientras se llena el formulario.
class ResumenEnVivo extends StatelessWidget {
  const ResumenEnVivo({super.key, required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    final prom = vm.borrador!.promediosCalidad();
    final pendientes = vm.problemasCierre;
    return ListView(
      padding: const EdgeInsets.all(GEspacio.l),
      children: [
        Text('Resumen en vivo', style: t.titleMedium),
        const SizedBox(height: GEspacio.m),
        for (final c in f.clasesCalidad)
          Padding(
            padding: const EdgeInsets.only(bottom: GEspacio.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.etiqueta, style: t.labelLarge)),
                    Text(Formato.porcentaje(prom[c.id]), style: GTipo.cifra(20)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (prom[c.id] ?? 0) / 100,
                    minHeight: 8,
                    backgroundColor: GColores.superficieAlt,
                    color: c == f.clasesCalidad.first ? GColores.secundario : GColores.acento,
                  ),
                ),
              ],
            ),
          ),
        Text('Promedio de ${vm.borrador!.muestras.length} muestras', style: t.bodySmall),
        const SizedBox(height: GEspacio.xl),
        Text('Para cerrar', style: t.titleSmall),
        const SizedBox(height: GEspacio.s),
        if (pendientes.isEmpty)
          const Aviso(mensaje: 'Todo completo. Puedes cerrar la evaluación.', tipo: TipoAviso.exito)
        else
          for (final p in pendientes.take(6))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsBold.circleDashed, size: 18, color: GColores.advertencia),
              title: Text(p.mensaje, style: t.bodySmall!.copyWith(color: GColores.tinta)),
              onTap: () => vm.irA(p.paso),
            ),
      ],
    );
  }
}
