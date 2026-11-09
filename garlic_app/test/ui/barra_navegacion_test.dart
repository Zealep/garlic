import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garlic_app/ui/core/theme/tema.dart';

/// La barra limita la escala de letra a 1.0 (shell_adaptativo). Con la fuente real (Inter) medimos que las etiquetas de la barra inferior no se partan en dos líneas.
void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final peso in [400, 500, 600, 700]) {
      inter.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Inter-$peso.ttf').readAsBytesSync())));
    }
    await inter.load();
  });

  for (final (ancho, escala) in [(360.0, 1.0), (384.0, 1.0), (412.0, 1.0)]) {
    testWidgets('"Evaluaciones" cabe en una línea ($ancho dp, letra x$escala)', (tester) async {
      tester.view.physicalSize = Size(ancho * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: TemaGarlic.claro(),
          home: MediaQuery(
            data: MediaQueryData(size: Size(ancho, 800), textScaler: TextScaler.linear(escala)),
            child: Scaffold(
              bottomNavigationBar: NavigationBar(
                destinations: [
                  for (final e in ['Inicio', 'Lotes', 'Evaluaciones', 'Sincronizar', 'Catálogos'])
                    NavigationDestination(icon: const Icon(Icons.circle), label: e),
                ],
              ),
            ),
          ),
        ),
      );

      double alto(String texto) => tester.renderObject<RenderParagraph>(find.text(texto)).size.height;
      expect(alto('Evaluaciones'), alto('Inicio'), reason: 'una sola línea');
      expect(alto('Sincronizar'), alto('Inicio'));
      expect(tester.takeException(), isNull);
    });
  }
}
