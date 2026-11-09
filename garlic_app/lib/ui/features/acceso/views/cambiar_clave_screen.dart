import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../routing/rutas.dart';
import '../../../../utils/result.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../view_models/cambiar_clave_view_model.dart';

class CambiarClaveScreen extends StatefulWidget {
  const CambiarClaveScreen({super.key, required this.viewModel});

  final CambiarClaveViewModel viewModel;

  @override
  State<CambiarClaveScreen> createState() => _CambiarClaveScreenState();
}

class _CambiarClaveScreenState extends State<CambiarClaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _ver = false;

  CambiarClaveViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final obligatorio = vm.obligatorio;
    vm
      ..actual = _actual.text
      ..nueva = _nueva.text;
    final r = await vm.guardar.execute();
    if (!mounted || r is! Ok<void>) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    // obligatorio: el router deja pasar a Inicio; voluntario: se vuelve a donde estaba
    if (obligatorio || !context.canPop()) {
      context.go(Rutas.inicio);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final obligatorio = vm.obligatorio;
    InputDecoration deco(String etiqueta, {String? ayuda}) => InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      prefixIcon: const Icon(PhosphorIconsRegular.lockKey),
      suffixIcon: IconButton(
        tooltip: _ver ? 'Ocultar' : 'Mostrar',
        icon: Icon(_ver ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye),
        onPressed: () => setState(() => _ver = !_ver),
      ),
    );
    return PopScope(
      canPop: !obligatorio,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cambiar contraseña'),
          automaticallyImplyLeading: !obligatorio,
          actions: [
            if (obligatorio)
              TextButton(onPressed: vm.cerrarSesion, child: const Text('Cerrar sesión')),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(GEspacio.xl),
          child: AnchoMaximo(
            max: 440,
            child: ListenableBuilder(
              listenable: vm.guardar,
              builder:
                  (context, _) => Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (obligatorio) ...[
                          Text('Hola, ${vm.nombre}', style: t.headlineSmall),
                          const SizedBox(height: GEspacio.s),
                          Text(
                            'Entraste con una contraseña temporal. Crea tu contraseña personal para continuar; '
                            'solo tú la conocerás.',
                            style: t.bodyMedium!.copyWith(color: GColores.tintaSuave),
                          ),
                          const SizedBox(height: GEspacio.xl),
                        ],
                        TextFormField(
                          controller: _actual,
                          obscureText: !_ver,
                          autofillHints: const [AutofillHints.password],
                          decoration: deco(obligatorio ? 'Contraseña temporal' : 'Contraseña actual'),
                          validator: (v) => (v ?? '').isEmpty ? 'Ingrese la contraseña actual' : null,
                        ),
                        const SizedBox(height: GEspacio.l),
                        TextFormField(
                          controller: _nueva,
                          obscureText: !_ver,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: deco(
                            'Nueva contraseña',
                            ayuda: 'Mínimo ${CambiarClaveViewModel.minimo} caracteres',
                          ),
                          validator: (v) => CambiarClaveViewModel.validarNueva(v, actual: _actual.text),
                        ),
                        const SizedBox(height: GEspacio.l),
                        TextFormField(
                          controller: _repetir,
                          obscureText: !_ver,
                          decoration: deco('Repetir nueva contraseña'),
                          validator: (v) => v != _nueva.text ? 'No coincide con la nueva contraseña' : null,
                          onFieldSubmitted: (_) => _guardar(),
                        ),
                        const SizedBox(height: GEspacio.l),
                        if (vm.guardar.failure != null) ...[
                          Aviso(mensaje: vm.guardar.failure!.message, tipo: TipoAviso.error),
                          const SizedBox(height: GEspacio.l),
                        ],
                        FilledButton.icon(
                          onPressed: vm.guardar.running ? null : _guardar,
                          icon: const Icon(PhosphorIconsBold.check),
                          label: Text(vm.guardar.running ? 'Guardando…' : 'Guardar contraseña'),
                        ),
                        const SizedBox(height: GEspacio.m),
                        Text(
                          'Necesitas conexión para cambiarla. Se cerrará tu sesión en otros dispositivos.',
                          style: t.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
