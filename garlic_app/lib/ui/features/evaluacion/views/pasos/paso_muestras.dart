import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/catalogo.dart';
import '../../../../../domain/models/evaluacion.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campo_porcentaje.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/evaluacion_view_model.dart';
import '../../../../core/widgets/galeria_fotos.dart';

/// Paso 2: muestras con factor de calidad global (2.1) y factor tamaño / calibre (2.2).
class PasoMuestras extends StatelessWidget {
  const PasoMuestras({super.key, required this.vm});

  final EvaluacionViewModel vm;

  /// Si la muestra tiene fotos, confirma antes de quitarla (también se eliminan sus fotos).
  Future<void> _quitarMuestra(BuildContext context, int numero) async {
    final nFotos = vm.fotosDe(SeccionFoto.muestra, muestraNumero: numero).length;
    if (nFotos > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('¿Quitar la muestra $numero?'),
              content: Text('Se eliminarán también sus $nFotos foto${nFotos == 1 ? '' : 's'}.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: GColores.error),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Quitar muestra'),
                ),
              ],
            ),
      );
      if (ok != true) return;
    }
    await vm.quitarMuestra(numero);
  }

  @override
  Widget build(BuildContext context) {
    final b = vm.borrador!;
    final m = vm.muestraActual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectorMuestras(vm: vm),
        const SizedBox(height: GEspacio.l),
        if (m == null)
          EstadoVacio(
            titulo: 'Sin muestras',
            mensaje: 'Agrega al menos una muestra representativa del lote.',
            accion: FilledButton.icon(
              onPressed: vm.agregarMuestra,
              icon: const Icon(PhosphorIconsBold.plus),
              label: const Text('Agregar muestra'),
            ),
          )
        else ...[
          _Calidad(vm: vm, muestra: m, key: ValueKey('cal-${m.numero}')),
          const SizedBox(height: GEspacio.l),
          _Calibres(vm: vm, muestra: m, key: ValueKey('calib-${m.numero}')),
          const SizedBox(height: GEspacio.l),
          GaleriaFotos(
            key: ValueKey('fotos-${m.numero}'),
            titulo: 'Fotos de la muestra ${m.numero}',
            ayuda: 'Evidencia de la calidad y el calibre de esta muestra.',
            fotos: vm.fotosDe(SeccionFoto.muestra, muestraNumero: m.numero),
            editable: vm.editable,
            onAgregar:
                (bytes, mime) => vm.agregarFoto(bytes, mime, seccion: SeccionFoto.muestra, muestraNumero: m.numero),
            onEliminar: vm.eliminarFoto,
          ),
          const SizedBox(height: GEspacio.l),
          TextFormField(
            key: ValueKey('obs-${m.numero}'),
            initialValue: m.observacion,
            decoration: InputDecoration(labelText: 'Observación de la muestra ${m.numero} (opcional)'),
            onChanged: vm.setObservacionMuestra,
          ),
          if (b.muestras.length > 1) ...[
            const SizedBox(height: GEspacio.s),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: GColores.error),
                onPressed: () => _quitarMuestra(context, m.numero),
                icon: const Icon(PhosphorIconsBold.trash),
                label: Text('Quitar muestra ${m.numero}'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _SelectorMuestras extends StatelessWidget {
  const _SelectorMuestras({required this.vm});

  final EvaluacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final muestras = vm.borrador!.muestras;
    final clases = vm.formulario!.clasesCalidad;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, m) in muestras.indexed) ...[
            _ChipMuestra(
              muestra: m,
              seleccionada: i == vm.muestraIndice,
              primera: clases.isEmpty ? null : m.calidad[clases.first.id],
              onTap: () => vm.seleccionarMuestra(i),
            ),
            const SizedBox(width: GEspacio.s),
          ],
          if (vm.editable)
            ActionChip(
              avatar: const Icon(PhosphorIconsBold.plus, size: 16),
              label: const Text('Muestra'),
              onPressed: vm.agregarMuestra,
            ),
        ],
      ),
    );
  }
}

class _ChipMuestra extends StatelessWidget {
  const _ChipMuestra({required this.muestra, required this.seleccionada, required this.onTap, this.primera});

  final MuestraBorrador muestra;
  final bool seleccionada;
  final double? primera;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completa = muestra.calidad.isNotEmpty && (muestra.totalCalidad - 100).abs() < .01;
    return Semantics(
      selected: seleccionada,
      button: true,
      child: Material(
        color: seleccionada ? GColores.primario : GColores.superficie,
        borderRadius: BorderRadius.circular(GRadio.chico),
        child: InkWell(
          borderRadius: BorderRadius.circular(GRadio.chico),
          onTap: onTap,
          child: Container(
            width: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GRadio.chico),
              border: Border.all(color: seleccionada ? GColores.primario : GColores.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Muestra ${muestra.numero}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: seleccionada ? Colors.white : GColores.tinta,
                      ),
                    ),
                    const Spacer(),
                    if (completa)
                      Icon(
                        PhosphorIconsFill.checkCircle,
                        size: 16,
                        color: seleccionada ? GColores.acento : GColores.secundario,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  primera == null ? '—' : Formato.porcentaje(primera),
                  style: GTipo.cifra(22, color: seleccionada ? Colors.white : GColores.primario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2.1 Calidad global. Con dos clases (PRIMERA/ABIERTOS): un deslizador y la otra se completa sola.
class _Calidad extends StatelessWidget {
  const _Calidad({super.key, required this.vm, required this.muestra});

  final EvaluacionViewModel vm;
  final MuestraBorrador muestra;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final clases = vm.formulario!.clasesCalidad;
    final total = muestra.totalCalidad;
    final ok = muestra.calidad.isEmpty || (total - 100).abs() < .01;
    return SeccionTarjeta(
      titulo: '2.1 Calidad global',
      icono: PhosphorIconsBold.sealPercent,
      accion:
          muestra.calidad.isEmpty
              ? null
              : Pastilla(
                texto: 'Total ${Formato.porcentaje(total)}',
                color: ok ? GColores.secundario : GColores.error,
                icono: ok ? PhosphorIconsBold.check : PhosphorIconsBold.warning,
              ),
      child:
          clases.length == 2
              ? _DosClases(vm: vm, muestra: muestra, clases: clases)
              : Column(
                children: [
                  for (final c in clases) ...[
                    CampoPorcentaje(
                      etiqueta: c.etiqueta,
                      valor: muestra.calidad[c.id],
                      habilitado: vm.editable,
                      onChanged: (v) => vm.setCalidad(c.id, v),
                    ),
                    const SizedBox(height: GEspacio.m),
                  ],
                  if (!ok)
                    Text(
                      'La calidad de cada muestra debe sumar 100%',
                      style: t.bodySmall!.copyWith(color: GColores.error),
                    ),
                ],
              ),
    );
  }
}

class _DosClases extends StatelessWidget {
  const _DosClases({required this.vm, required this.muestra, required this.clases});

  final EvaluacionViewModel vm;
  final MuestraBorrador muestra;
  final List<CatalogoItem> clases;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = clases[0];
    final b = clases[1];
    final va = muestra.calidad[a.id];
    final vb = muestra.calidad[b.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Cifra(etiqueta: a.etiqueta, valor: va, color: GColores.secundario)),
            Expanded(child: _Cifra(etiqueta: b.etiqueta, valor: vb, color: GColores.advertencia, alinearFin: true)),
          ],
        ),
        const SizedBox(height: GEspacio.m),
        // Barra proporcional: se lee de un vistazo al sol
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(flex: ((va ?? 0) * 10).round(), child: const ColoredBox(color: GColores.secundario)),
                Expanded(
                  flex: ((vb ?? (va == null ? 100 : 0)) * 10).round(),
                  child: ColoredBox(color: va == null ? GColores.superficieAlt : GColores.acento),
                ),
              ],
            ),
          ),
        ),
        Slider(
          value: va ?? 0,
          max: 100,
          divisions: 100,
          label: Formato.porcentaje(va ?? 0),
          semanticFormatterCallback: (v) => '${a.etiqueta} ${v.round()} por ciento',
          onChanged: vm.editable ? (v) => vm.setCalidad(a.id, v.roundToDouble()) : null,
        ),
        Row(
          children: [
            Expanded(
              child: CampoPorcentaje(
                etiqueta: a.etiqueta,
                valor: va,
                habilitado: vm.editable,
                onChanged: (v) => vm.setCalidad(a.id, v),
              ),
            ),
            const SizedBox(width: GEspacio.m),
            Expanded(
              child: CampoPorcentaje(
                etiqueta: b.etiqueta,
                valor: vb,
                habilitado: vm.editable,
                onChanged: (v) => vm.setCalidad(b.id, v),
              ),
            ),
          ],
        ),
        const SizedBox(height: GEspacio.s),
        Text('${b.etiqueta} se calcula como 100% − ${a.etiqueta.toLowerCase()}', style: t.bodySmall),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.etiqueta, required this.valor, required this.color, this.alinearFin = false});

  final String etiqueta;
  final double? valor;
  final Color color;
  final bool alinearFin;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alinearFin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(
        etiqueta.toUpperCase(),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color, letterSpacing: .6),
      ),
      Text(valor == null ? '—' : Formato.porcentaje(valor), style: GTipo.cifra(34)),
    ],
  );
}

/// 2.2 Factor tamaño: el evaluador elige del catálogo los calibres presentes en la muestra
/// e ingresa su %; deben sumar 100% para cerrar (se permiten rangos superpuestos, ej. 50/60).
class _Calibres extends StatelessWidget {
  const _Calibres({super.key, required this.vm, required this.muestra});

  final EvaluacionViewModel vm;
  final MuestraBorrador muestra;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final catalogo = vm.formulario!.calibres;
    final elegidos = catalogo.where((c) => muestra.calibres.containsKey(c.id)).toList();
    final falta = muestra.faltaCalibres;
    return SeccionTarjeta(
      titulo: '2.2 Calibre (tamaño)',
      icono: PhosphorIconsBold.ruler,
      accion: elegidos.isEmpty ? null : _EstadoTotal(falta: falta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vm.editable ? 'Elige los calibres presentes en la muestra' : 'Calibres de la muestra',
            style: t.bodySmall,
          ),
          const SizedBox(height: GEspacio.s),
          if (vm.editable)
            Wrap(
              spacing: GEspacio.s,
              runSpacing: GEspacio.s,
              children: [
                for (final c in catalogo)
                  FilterChip(
                    label: Text(c.codigo),
                    tooltip: _rango(c),
                    selected: muestra.calibres.containsKey(c.id),
                    onSelected: (_) => vm.alternarCalibre(c.id),
                  ),
              ],
            ),
          if (elegidos.isNotEmpty) ...[
            const SizedBox(height: GEspacio.l),
            for (final c in elegidos)
              Padding(
                padding: const EdgeInsets.only(bottom: GEspacio.s),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.codigo, style: t.titleMedium!.copyWith(fontFamily: GTipo.titulos)),
                          Text(_rango(c), style: t.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CampoPorcentaje(
                        key: ValueKey('calibre-${muestra.numero}-${c.id}'),
                        etiqueta: 'Porcentaje',
                        pista: 'Ingrese %',
                        valor: (muestra.calibres[c.id] ?? 0) == 0 ? null : muestra.calibres[c.id],
                        habilitado: vm.editable,
                        onChanged: (v) => vm.setCalibre(c.id, v),
                      ),
                    ),
                    if (vm.editable)
                      IconButton(
                        tooltip: 'Quitar ${c.codigo}',
                        icon: const Icon(PhosphorIconsRegular.x, color: GColores.tintaSuave),
                        onPressed: () => vm.alternarCalibre(c.id),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: GEspacio.s),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (muestra.totalCalibres / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: GColores.superficieAlt,
                color: _colorTotal(falta),
              ),
            ),
            const SizedBox(height: GEspacio.s),
            Row(
              children: [
                Expanded(
                  child: Text(
                    falta == 0
                        ? 'Los calibres suman 100%'
                        : falta > 0
                        ? 'Falta ${Formato.porcentaje(falta)} para llegar a 100%'
                        : 'Se pasan por ${Formato.porcentaje(-falta)}: ajusta los valores',
                    style: t.bodySmall!.copyWith(color: falta == 0 ? GColores.secundario : _colorTotal(falta)),
                  ),
                ),
                if (vm.editable && falta > 0)
                  TextButton.icon(
                    onPressed: vm.completarCalibres,
                    icon: const Icon(PhosphorIconsBold.magicWand, size: 18),
                    label: const Text('Completar 100%'),
                  ),
              ],
            ),
          ] else if (!vm.editable)
            Text('Sin calibres', style: t.bodySmall),
        ],
      ),
    );
  }

  static String _rango(CatalogoItem c) {
    String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    final min = c.diametroMinMm;
    final max = c.diametroMaxMm;
    if (min == null) return c.nombre;
    return max == null ? 'más de ${n(min)} mm' : '${n(min)}–${n(max)} mm';
  }
}

Color _colorTotal(double falta) =>
    falta == 0
        ? GColores.secundario
        : falta > 0
        ? GColores.advertencia
        : GColores.error;

/// Pastilla con el estado del total de calibres: 100% ✓ · Falta X% · Sobra X%.
class _EstadoTotal extends StatelessWidget {
  const _EstadoTotal({required this.falta});

  final double falta;

  @override
  Widget build(BuildContext context) {
    if (falta == 0) {
      return const Pastilla(texto: '100%', color: GColores.secundario, icono: PhosphorIconsBold.check);
    }
    return Pastilla(
      texto: falta > 0 ? 'Falta ${Formato.porcentaje(falta)}' : 'Sobra ${Formato.porcentaje(-falta)}',
      color: _colorTotal(falta),
      icono: PhosphorIconsBold.warning,
    );
  }
}
