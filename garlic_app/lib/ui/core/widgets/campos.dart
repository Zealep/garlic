import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../utils/formato.dart';
import '../theme/colores.dart';
import '../theme/tema.dart';

/// Campo de fecha con selector nativo; etiqueta visible siempre.
class CampoFecha extends StatelessWidget {
  const CampoFecha({super.key, required this.etiqueta, required this.valor, required this.onChanged, this.ayuda});

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> onChanged;
  final String? ayuda;

  Future<void> _elegir(BuildContext context) async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: valor ?? hoy,
      firstDate: DateTime(hoy.year - 2),
      lastDate: DateTime(hoy.year + 1),
      locale: const Locale('es'),
    );
    if (d != null) onChanged(d);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(GRadio.chico),
    onTap: () => _elegir(context),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        prefixIcon: const Icon(PhosphorIconsRegular.calendarBlank),
        suffixIcon:
            valor == null
                ? null
                : IconButton(
                  tooltip: 'Quitar fecha',
                  icon: const Icon(PhosphorIconsRegular.x, size: 18),
                  onPressed: () => onChanged(null),
                ),
      ),
      isEmpty: valor == null,
      child: Text(valor == null ? '' : Formato.fecha(valor)),
    ),
  );
}

/// Selección única como chips (pocas opciones: más rápida que un desplegable en campo).
class SelectorChips<T> extends StatelessWidget {
  const SelectorChips({
    super.key,
    required this.etiqueta,
    required this.opciones,
    required this.seleccion,
    required this.texto,
    required this.onChanged,
    this.error,
  });

  final String etiqueta;
  final List<T> opciones;
  final T? seleccion;
  final String Function(T) texto;
  final ValueChanged<T> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: t.labelLarge),
        const SizedBox(height: GEspacio.s),
        Wrap(
          spacing: GEspacio.s,
          runSpacing: GEspacio.s,
          children: [
            for (final o in opciones)
              ChoiceChip(label: Text(texto(o)), selected: o == seleccion, onSelected: (_) => onChanged(o)),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: t.bodySmall!.copyWith(color: GColores.error)),
        ],
      ],
    );
  }
}

/// Título de grupo dentro de un formulario largo.
class TituloGrupo extends StatelessWidget {
  const TituloGrupo(this.texto, {super.key, this.subtitulo, this.icono});

  final String texto;
  final String? subtitulo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: GEspacio.xl, bottom: GEspacio.m),
      child: Row(
        children: [
          if (icono != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: GColores.primarioSuave, borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, size: 18, color: GColores.primario),
            ),
            const SizedBox(width: GEspacio.m),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: t.titleMedium),
                if (subtitulo != null) Text(subtitulo!, style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
