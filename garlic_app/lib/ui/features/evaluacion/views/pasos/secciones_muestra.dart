import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../domain/models/catalogo.dart';
import '../../../../../domain/models/evaluacion.dart';
import '../../../../../utils/formato.dart';
import '../../../../core/theme/colores.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/widgets/campo_numero.dart';
import '../../../../core/widgets/campo_porcentaje.dart';
import '../../../../core/widgets/componentes.dart';
import '../../view_models/evaluacion_view_model.dart';

/// Sensoriales de una muestra: humedad (SI/NO por indicador), empaste y daños no visibles
/// (con frutos total y con problema en los que lo piden, p. ej. parálisis).
class SeccionSensoriales extends StatelessWidget {
  const SeccionSensoriales({super.key, required this.vm, required this.muestra});

  final EvaluacionViewModel vm;
  final MuestraBorrador muestra;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    final anterior = vm.muestraAnterior;
    return SeccionTarjeta(
      titulo: 'Sensoriales',
      icono: PhosphorIconsBold.drop,
      accion:
          vm.editable && anterior != null
              ? TextButton.icon(
                onPressed: vm.copiarDeAnterior,
                icon: const Icon(PhosphorIconsBold.copy, size: 16),
                label: Text('Copiar de M${anterior.numero}'),
              )
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('2.2.1 Humedad', style: t.titleSmall),
          const SizedBox(height: GEspacio.s),
          for (final tipo in f.tiposHumedad) ...[
            FilaSiNo(
              etiqueta: tipo.etiqueta,
              valor: muestra.humedad[tipo.id],
              onChanged: (v) => vm.setHumedad(tipo.id, v),
              textoSinResponder: 'No observado',
            ),
            if (tipo != f.tiposHumedad.last) const Divider(height: GEspacio.l),
          ],
          const SizedBox(height: GEspacio.xl),
          Text('2.2.2 Empaste', style: t.titleSmall),
          const SizedBox(height: GEspacio.s),
          Wrap(
            spacing: GEspacio.s,
            runSpacing: GEspacio.s,
            children: [
              for (final e in f.tiposEmpaste)
                FilterChip(
                  label: Text(e.etiqueta),
                  selected: muestra.empastes.contains(e.id),
                  onSelected: (_) => vm.alternarEmpaste(e.id),
                ),
            ],
          ),
          const SizedBox(height: GEspacio.xl),
          Text('Daños no visibles', style: t.titleSmall),
          const SizedBox(height: GEspacio.s),
          Wrap(
            spacing: GEspacio.s,
            runSpacing: GEspacio.s,
            children: [
              for (final d in f.tiposDano)
                FilterChip(
                  label: Text(d.etiqueta),
                  selected: muestra.danos.containsKey(d.id),
                  selectedColor: d.esExcluyente ? GColores.secundarioSuave : GColores.errorSuave,
                  checkmarkColor: d.esExcluyente ? GColores.secundario : GColores.error,
                  onSelected: (_) => vm.alternarDano(d),
                ),
            ],
          ),
          const SizedBox(height: GEspacio.s),
          Text('"No contiene" desmarca los demás daños.', style: t.bodySmall),
          for (final d in f.tiposDano.where((d) => d.pideCantidades && muestra.danos.containsKey(d.id)))
            _CantidadesDano(key: ValueKey('dano-${muestra.id}-${d.id}'), vm: vm, tipo: d, dano: muestra.danos[d.id]!),
        ],
      ),
    );
  }
}

/// Frutos total y con problema de un daño (parálisis) y su % calculado.
class _CantidadesDano extends StatelessWidget {
  const _CantidadesDano({super.key, required this.vm, required this.tipo, required this.dano});

  final EvaluacionViewModel vm;
  final CatalogoItem tipo;
  final DanoBorrador dano;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = dano.porcentaje;
    final excedido = dano.total != null && dano.afectados != null && dano.afectados! > dano.total!;
    return Container(
      margin: const EdgeInsets.only(top: GEspacio.m),
      padding: const EdgeInsets.all(GEspacio.m),
      decoration: BoxDecoration(color: GColores.errorSuave, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(tipo.etiqueta, style: t.titleSmall)),
              Text(
                pct == null || excedido ? '— %' : Formato.porcentaje(pct),
                style: GTipo.cifra(22).copyWith(color: GColores.error),
              ),
            ],
          ),
          const SizedBox(height: GEspacio.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CampoNumero(
                  etiqueta: 'Frutos total',
                  entero: true,
                  valor: dano.total?.toDouble(),
                  habilitado: vm.editable,
                  onChanged: (v) => vm.setFrutosDano(tipo.id, total: v?.toInt(), limpiarTotal: v == null),
                ),
              ),
              const SizedBox(width: GEspacio.m),
              Expanded(
                child: CampoNumero(
                  etiqueta: 'Con problema',
                  entero: true,
                  valor: dano.afectados?.toDouble(),
                  habilitado: vm.editable,
                  onChanged: (v) => vm.setFrutosDano(tipo.id, afectados: v?.toInt(), limpiarAfectados: v == null),
                ),
              ),
            ],
          ),
          if (excedido) ...[
            const SizedBox(height: GEspacio.xs),
            Text('No pueden ser más que el total', style: t.bodySmall!.copyWith(color: GColores.error)),
          ],
        ],
      ),
    );
  }
}

/// Sanidad de una muestra (Raíz rosada, Fusarium y demás a evaluar en campo): SI/NO + %.
class SeccionSanidad extends StatelessWidget {
  const SeccionSanidad({super.key, required this.vm, required this.muestra});

  final EvaluacionViewModel vm;
  final MuestraBorrador muestra;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = vm.formulario!;
    return SeccionTarjeta(
      titulo: 'Sanidad',
      icono: PhosphorIconsBold.virus,
      child:
          f.enfermedades.isEmpty
              ? Text('La empresa no marcó enfermedades para evaluar en campo.', style: t.bodySmall)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in f.enfermedades) ...[
                    FilaSiNo(
                      etiqueta: e.etiqueta,
                      subtitulo: e.nombreCientifico,
                      valor: muestra.sanidad[e.id]?.presente,
                      onChanged: (v) {
                        if (v != null) vm.setPresente(e.id, v);
                      },
                      textoSinResponder: 'Responda SÍ o NO',
                      alertaSinResponder: true,
                    ),
                    if (muestra.sanidad[e.id]?.presente == true) ...[
                      const SizedBox(height: GEspacio.m),
                      CampoPorcentaje(
                        key: ValueKey('san-${muestra.id}-${e.id}'),
                        etiqueta: '¿Qué porcentaje tiene?',
                        valor: muestra.sanidad[e.id]?.porcentaje,
                        habilitado: vm.editable,
                        onChanged: (v) => vm.setPorcentajeEnfermedad(e.id, v),
                      ),
                    ],
                    if (e != f.enfermedades.last) const Divider(height: GEspacio.xl),
                  ],
                ],
              ),
    );
  }
}

/// Pregunta SI/NO (humedad, enfermedad). SI se pinta en rojo (es lo que se busca evitar).
class FilaSiNo extends StatelessWidget {
  const FilaSiNo({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.subtitulo,
    this.textoSinResponder,
    this.alertaSinResponder = false,
  });

  final String etiqueta;
  final String? subtitulo;
  final bool? valor;

  /// null = sin responder (tocar la opción marcada la desmarca).
  final ValueChanged<bool?> onChanged;
  final String? textoSinResponder;
  final bool alertaSinResponder;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: t.titleSmall),
              if (subtitulo != null) Text(subtitulo!, style: t.bodySmall!.copyWith(fontStyle: FontStyle.italic)),
              if (valor == null && textoSinResponder != null)
                Text(
                  textoSinResponder!,
                  style: t.bodySmall!.copyWith(color: alertaSinResponder ? GColores.advertencia : null),
                ),
            ],
          ),
        ),
        const SizedBox(width: GEspacio.s),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: false, label: Text('NO')),
            ButtonSegment(value: true, label: Text('SÍ')),
          ],
          selected: {if (valor != null) valor!},
          onSelectionChanged: (sel) => onChanged(sel.isEmpty ? null : sel.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            backgroundColor: WidgetStateProperty.resolveWith((st) {
              if (!st.contains(WidgetState.selected)) return null;
              return valor == true ? GColores.errorSuave : GColores.secundarioSuave;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((st) {
              if (!st.contains(WidgetState.selected)) return GColores.tintaSuave;
              return valor == true ? GColores.error : GColores.secundario;
            }),
          ),
        ),
      ],
    );
  }
}
