import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tema.dart';

/// Campo numérico de porcentaje (0–100, hasta 2 decimales) con teclado numérico.
/// Se sincroniza con el valor externo cuando no tiene el foco (p. ej. complemento automático).
class CampoPorcentaje extends StatefulWidget {
  const CampoPorcentaje({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
    this.denso = false,
    this.pista,
  });

  final String etiqueta;
  final double? valor;
  final ValueChanged<double?> onChanged;
  final bool habilitado;
  final bool denso;

  /// Texto de ayuda dentro del campo cuando está vacío (ej. "Ingrese %").
  final String? pista;

  @override
  State<CampoPorcentaje> createState() => _CampoPorcentajeState();
}

class _CampoPorcentajeState extends State<CampoPorcentaje> {
  late final _ctrl = TextEditingController(text: _texto(widget.valor));
  final _foco = FocusNode();

  static String _texto(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }

  @override
  void didUpdateWidget(covariant CampoPorcentaje old) {
    super.didUpdateWidget(old);
    if (!_foco.hasFocus && old.valor != widget.valor) _ctrl.text = _texto(widget.valor);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  String? _error(String? t) {
    if (t == null || t.isEmpty) return null;
    final v = double.tryParse(t.replaceAll(',', '.'));
    if (v == null) return 'Número inválido';
    if (v < 0 || v > 100) return 'Entre 0 y 100';
    return null;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _ctrl,
    focusNode: _foco,
    enabled: widget.habilitado,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d{0,2})?'))],
    textAlign: TextAlign.end,
    style: const TextStyle(fontFeatures: GTipo.tabular, fontWeight: FontWeight.w600, fontSize: 16),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: _error,
    decoration: InputDecoration(
      labelText: widget.etiqueta,
      hintText: widget.pista,
      suffixText: '%',
      isDense: widget.denso,
    ),
    onChanged: (t) {
      if (_error(t) != null) return;
      widget.onChanged(t.isEmpty ? null : double.parse(t.replaceAll(',', '.')));
    },
  );
}
