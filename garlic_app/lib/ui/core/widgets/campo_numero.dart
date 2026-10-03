import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tema.dart';

/// Campo numérico (kg, soles, precio por kg) con teclado numérico; acepta coma o punto decimal.
/// Se sincroniza con el valor externo cuando no tiene el foco (p. ej. "Usar precio técnico").
class CampoNumero extends StatefulWidget {
  const CampoNumero({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.decimales = 2,
    this.prefijo,
    this.sufijo,
    this.ayuda,
    this.habilitado = true,
    this.maximo,
    this.entero = false,
    this.autofocus = false,
  });

  final String etiqueta;
  final double? valor;
  final ValueChanged<double?> onChanged;
  final int decimales;
  final String? prefijo;
  final String? sufijo;
  final String? ayuda;
  final bool habilitado;
  final double? maximo;
  final bool entero;
  final bool autofocus;

  @override
  State<CampoNumero> createState() => _CampoNumeroState();
}

class _CampoNumeroState extends State<CampoNumero> {
  late final _ctrl = TextEditingController(text: _texto(widget.valor));
  final _foco = FocusNode();

  String _texto(double? v) {
    if (v == null) return '';
    if (widget.entero || v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(widget.decimales).replaceFirst(RegExp(r'0+$'), '');
  }

  @override
  void didUpdateWidget(covariant CampoNumero old) {
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
    if (widget.maximo != null && v > widget.maximo!) return 'Máximo ${_texto(widget.maximo)}';
    return null;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _ctrl,
    focusNode: _foco,
    enabled: widget.habilitado,
    autofocus: widget.autofocus,
    keyboardType: TextInputType.numberWithOptions(decimal: !widget.entero),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        widget.entero ? RegExp(r'^\d{0,9}') : RegExp(r'^\d{0,9}([.,]\d{0,' '${widget.decimales}' r'})?'),
      ),
    ],
    textAlign: TextAlign.end,
    style: const TextStyle(fontFeatures: GTipo.tabular, fontWeight: FontWeight.w600, fontSize: 16),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: _error,
    decoration: InputDecoration(
      labelText: widget.etiqueta,
      prefixText: widget.prefijo,
      suffixText: widget.sufijo,
      helperText: widget.ayuda,
    ),
    onChanged: (t) {
      if (_error(t) != null) return;
      widget.onChanged(t.isEmpty ? null : double.parse(t.replaceAll(',', '.')));
    },
  );
}
