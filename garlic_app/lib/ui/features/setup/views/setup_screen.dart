import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../routing/rutas.dart';
import '../../../../utils/result.dart';
import '../../../core/theme/colores.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/componentes.dart';
import '../../../core/widgets/marca.dart';
import '../view_models/setup_view_model.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.viewModel});

  final SetupViewModel viewModel;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _url = TextEditingController(text: widget.viewModel.apiUrl);

  SetupViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _conectar() async {
    if (!_formKey.currentState!.validate()) return;
    vm.apiUrl = _url.text;
    await vm.conectar.execute();
  }

  Future<void> _finalizar() async {
    final r = await vm.finalizar.execute();
    if (!mounted) return;
    if (r is Ok<void>) context.go(Rutas.inicio);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= 900;
          final panel = _panelFormulario(t);
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
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: panel),
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
      padding: EdgeInsets.fromLTRB(28, compacto ? 28 : 64, 28, compacto ? 36 : 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compacto ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          const GarlicWordmark(claro: true),
          SizedBox(height: compacto ? 28 : 48),
          Text(
            'Calidad de lotes,\ndesde el campo.',
            style: t.displaySmall!.copyWith(color: Colors.white, fontSize: compacto ? 30 : 46, height: 1.05),
          ),
          const SizedBox(height: GEspacio.m),
          Text(
            'Evalúa muestras, humedad y sanidad aunque no haya señal. '
            'Todo se sincroniza solo cuando vuelve la conexión.',
            style: t.bodyLarge!.copyWith(color: Colors.white.withValues(alpha: .82)),
          ),
          if (!compacto) ...[
            const SizedBox(height: 40),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Beneficio(icono: PhosphorIconsBold.wifiSlash, texto: 'Funciona sin conexión'),
                _Beneficio(icono: PhosphorIconsBold.camera, texto: 'Fotos por muestra'),
                _Beneficio(icono: PhosphorIconsBold.chartBar, texto: 'Promedios al instante'),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget _panelFormulario(TextTheme t) => ListenableBuilder(
    listenable: Listenable.merge([vm, vm.conectar, vm.elegirEmpresa, vm.finalizar]),
    builder:
        (context, _) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Configurar dispositivo', style: t.headlineSmall),
              const SizedBox(height: 4),
              Text('Paso ${vm.paso + 1} de 3', style: t.bodySmall),
              const SizedBox(height: GEspacio.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (vm.paso + 1) / 3,
                  minHeight: 6,
                  backgroundColor: GColores.superficieAlt,
                ),
              ),
              const SizedBox(height: GEspacio.xxl),
              ...switch (vm.paso) {
                0 => _pasoServidor(t),
                1 => _pasoEmpresa(t),
                _ => _pasoEvaluador(t),
              },
            ],
          ),
        ),
  );

  List<Widget> _pasoServidor(TextTheme t) => [
    TextFormField(
      controller: _url,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'Servidor',
        helperText: 'Dirección del API de Garlic (emulador Android: 10.0.2.2)',
        prefixIcon: Icon(PhosphorIconsRegular.globe),
      ),
      validator: (v) => (v == null || !v.startsWith('http')) ? 'Ingrese una URL que empiece con http' : null,
      onFieldSubmitted: (_) => _conectar(),
    ),
    const SizedBox(height: GEspacio.l),
    if (vm.conectar.failure != null) ...[
      Aviso(mensaje: 'No se pudo conectar: ${vm.conectar.failure!.message}', tipo: TipoAviso.error),
      const SizedBox(height: GEspacio.l),
    ],
    FilledButton.icon(
      onPressed: vm.conectar.running ? null : _conectar,
      icon: vm.conectar.running ? const _Spinner() : const Icon(PhosphorIconsBold.plugsConnected),
      label: const Text('Conectar'),
    ),
  ];

  List<Widget> _pasoEmpresa(TextTheme t) => [
    Text('¿Para qué empresa trabajas?', style: t.titleMedium),
    const SizedBox(height: GEspacio.m),
    for (final e in vm.empresas) ...[
      Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: const CircleAvatar(
            backgroundColor: GColores.primarioSuave,
            child: Icon(PhosphorIconsFill.buildings, color: GColores.primario),
          ),
          title: Text(e.nombre, style: t.titleSmall),
          subtitle: Text('RUC ${e.ruc}'),
          trailing: vm.elegirEmpresa.running ? const _Spinner(oscuro: true) : const Icon(PhosphorIconsBold.caretRight),
          onTap: vm.elegirEmpresa.running ? null : () => vm.elegirEmpresa.execute(e),
        ),
      ),
      const SizedBox(height: GEspacio.s),
    ],
    if (vm.elegirEmpresa.failure != null) Aviso(mensaje: vm.elegirEmpresa.failure!.message, tipo: TipoAviso.error),
    TextButton.icon(
      onPressed: vm.volver,
      icon: const Icon(PhosphorIconsBold.arrowLeft),
      label: const Text('Cambiar servidor'),
    ),
  ];

  List<Widget> _pasoEvaluador(TextTheme t) => [
    Text(vm.empresa!.nombre, style: t.titleMedium),
    const SizedBox(height: 2),
    Text('Cultivo: ${vm.cultivo?.nombre ?? '—'}', style: t.bodySmall),
    const SizedBox(height: GEspacio.xl),
    DropdownButtonFormField<String>(
      value: vm.evaluador?.id,
      decoration: const InputDecoration(labelText: 'Evaluador', prefixIcon: Icon(PhosphorIconsRegular.userCircle)),
      items: [for (final e in vm.evaluadores) DropdownMenuItem(value: e.id, child: Text(e.nombreVisible))],
      onChanged: (id) => vm.seleccionarEvaluador(vm.evaluadores.where((e) => e.id == id).firstOrNull),
      validator: (v) => v == null ? 'Seleccione el evaluador' : null,
    ),
    const SizedBox(height: GEspacio.l),
    const Aviso(
      mensaje: 'Se descargarán los catálogos y lotes para trabajar sin conexión en campo.',
      tipo: TipoAviso.info,
    ),
    if (vm.finalizar.failure != null) ...[
      const SizedBox(height: GEspacio.m),
      Aviso(mensaje: vm.finalizar.failure!.message, tipo: TipoAviso.error),
    ],
    const SizedBox(height: GEspacio.l),
    FilledButton.icon(
      onPressed: vm.finalizar.running || vm.evaluador == null ? null : _finalizar,
      icon: vm.finalizar.running ? const _Spinner() : const Icon(PhosphorIconsBold.downloadSimple),
      label: Text(vm.finalizar.running ? 'Descargando…' : 'Descargar y empezar'),
    ),
    TextButton.icon(
      onPressed: vm.volver,
      icon: const Icon(PhosphorIconsBold.arrowLeft),
      label: const Text('Otra empresa'),
    ),
  ];
}

class _Beneficio extends StatelessWidget {
  const _Beneficio({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: GColores.acento),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
      ],
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.oscuro = false});

  final bool oscuro;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2.2, color: oscuro ? GColores.primario : Colors.white),
  );
}
