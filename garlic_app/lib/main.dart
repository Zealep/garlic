import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/dependencias.dart';
import 'routing/router.dart';
import 'ui/core/theme/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final deps = await Dependencias.iniciar();
  runApp(GarlicApp(dependencias: deps));
}

class GarlicApp extends StatefulWidget {
  const GarlicApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<GarlicApp> createState() => _GarlicAppState();
}

class _GarlicAppState extends State<GarlicApp> {
  late final GoRouter _router = crearRouter(widget.dependencias.config);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: widget.dependencias.providers,
      child: MaterialApp.router(
        title: 'Garlic',
        debugShowCheckedModeBanner: false,
        theme: TemaGarlic.claro(),
        routerConfig: _router,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
