import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/marca.dart';
import '../view_models/acceso_view_model.dart';

/// Inicio de sesión: DNI + contraseña. La navegación al entrar la decide el router (sesión activa).
class AccesoScreen extends StatefulWidget {
  const AccesoScreen({super.key, required this.viewModel});

  final AccesoViewModel viewModel;

  @override
  State<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends State<AccesoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _dni = TextEditingController(text: widget.viewModel.ultimoDni ?? '');
  final _clave = TextEditingController();
  late final _url = TextEditingController(text: widget.viewModel.apiUrl);
  final _focoClave = FocusNode();
  bool _verClave = false;

  AccesoViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    _dni.dispose();
    _clave.dispose();
    _url.dispose();
    _focoClave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    vm
      ..dni = _dni.text
      ..clave = _clave.text
      ..apiUrl = _url.text;
    await vm.ingresar.execute();
    if (mounted && vm.ingresar.failure != null) _clave.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= 900;
          final panel = _panel(t);
          if (!ancho) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  FondoMarca(child: _hero(t, compacto: true)),
                  Padding(padding: const EdgeInsets.all(GEspacio.xl), child: panel),
                ],
              ),
            );
          }
          return Row(
            children: [
              Expanded(flex: 5, child: FondoMarca(radioInferior: 0, child: _hero(t, compacto: false))),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(GEspacio.xxxl),
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: panel),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(TextTheme t, {required bool compacto}) => SafeArea(
    bottom: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(28, compacto ? 28 : 64, 28, compacto ? 32 : 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compacto ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          const LogoMarca(claro: true, alto: 44),
          SizedBox(height: compacto ? 24 : 48),
          Text(
            'Compra de ajo,\ndesde el campo.',
            style: t.displaySmall!.copyWith(color: Colors.white, fontSize: compacto ? 28 : 44, height: 1.05),
          ),
          const SizedBox(height: GEspacio.m),
          Text(
            'Evalúa lotes, fija precios y registra cargas y pagos aunque no haya señal.',
            style: t.bodyLarge!.copyWith(color: Colors.white.withValues(alpha: .82)),
          ),
        ],
      ),
    ),
  );

  Widget _panel(TextTheme t) => ListenableBuilder(
    listenable: vm.ingresar,
    builder:
        (context, _) => AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Iniciar sesión', style: t.headlineSmall),
                const SizedBox(height: 4),
                Text('Ingresa con tu DNI y tu contraseña.', style: t.bodyMedium!.copyWith(color: GColores.tintaSuave)),
                const SizedBox(height: GEspacio.xl),
                if (vm.sesionExpirada) ...[
                  const Aviso(
                    mensaje:
                        'Tu sesión expiró. Vuelve a ingresar: lo que registraste sin conexión sigue guardado '
                        'y se enviará al entrar.',
                    tipo: TipoAviso.advertencia,
                  ),
                  const SizedBox(height: GEspacio.l),
                ],
                TextFormField(
                  controller: _dni,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: const InputDecoration(labelText: 'DNI', prefixIcon: Icon(PhosphorIconsRegular.identificationCard)),
                  validator: (v) => (v ?? '').length != 8 ? 'El DNI tiene 8 dígitos' : null,
                  onFieldSubmitted: (_) => _focoClave.requestFocus(),
                ),
                const SizedBox(height: GEspacio.l),
                TextFormField(
                  controller: _clave,
                  focusNode: _focoClave,
                  obscureText: !_verClave,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(PhosphorIconsRegular.lockKey),
                    suffixIcon: IconButton(
                      tooltip: _verClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                      icon: Icon(_verClave ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye),
                      onPressed: () => setState(() => _verClave = !_verClave),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Ingrese su contraseña' : null,
                  onFieldSubmitted: (_) => _ingresar(),
                ),
                if (!AccesoViewModel.servidorFijo) ...[
                  const SizedBox(height: GEspacio.s),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('Servidor', style: t.labelLarge),
                      subtitle: Text(_url.text, style: t.bodySmall),
                      children: [
                        TextFormField(
                          controller: _url,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Dirección del servidor',
                            helperText: 'Emulador Android: http://10.0.2.2:8080',
                            prefixIcon: Icon(PhosphorIconsRegular.globe),
                          ),
                          validator: (v) => (v == null || !v.startsWith('http')) ? 'Debe empezar con http' : null,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: GEspacio.l),
                if (vm.ingresar.failure != null) ...[
                  Aviso(mensaje: vm.ingresar.failure!.message, tipo: TipoAviso.error),
                  const SizedBox(height: GEspacio.l),
                ],
                FilledButton.icon(
                  onPressed: vm.ingresar.running ? null : _ingresar,
                  icon:
                      vm.ingresar.running
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                          : const Icon(PhosphorIconsBold.signIn),
                  label: Text(vm.ingresar.running ? 'Ingresando…' : 'Ingresar'),
                ),
                const SizedBox(height: GEspacio.l),
                Text(
                  '¿Olvidaste tu contraseña? Pídele al administrador que te asigne una nueva.',
                  style: t.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
  );
}
