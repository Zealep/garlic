import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colores.dart';
import '../theme/tema.dart';

/// Sello de marca: cabeza de ajo con dientes y vetas moradas, dibujada en vector.
class GarlicMark extends StatelessWidget {
  const GarlicMark({super.key, this.size = 48, this.claro = false});

  final double size;

  /// Versión para fondos oscuros (morado).
  final bool claro;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Garlic',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: _AjoPainter(claro: claro)),
  );
}

class _AjoPainter extends CustomPainter {
  _AjoPainter({required this.claro, this.soloContorno = false, this.opacidad = 1});

  final bool claro;
  final bool soloContorno;
  final double opacidad;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    final cuerpo =
        Path()
          ..moveTo(p(.5, .10).dx, p(.5, .10).dy)
          ..cubicTo(p(.57, .26).dx, p(.57, .26).dy, p(.95, .40).dx, p(.95, .40).dy, p(.93, .64).dx, p(.93, .64).dy)
          ..cubicTo(p(.91, .86).dx, p(.91, .86).dy, p(.72, .95).dx, p(.72, .95).dy, p(.5, .95).dx, p(.5, .95).dy)
          ..cubicTo(p(.28, .95).dx, p(.28, .95).dy, p(.09, .86).dx, p(.09, .86).dy, p(.07, .64).dx, p(.07, .64).dy)
          ..cubicTo(p(.05, .40).dx, p(.05, .40).dy, p(.43, .26).dx, p(.43, .26).dy, p(.5, .10).dx, p(.5, .10).dy)
          ..close();

    final trazo = (claro ? Colors.white : GColores.primario).withValues(alpha: opacidad);
    final linea =
        Paint()
          ..color = trazo
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * .045)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    if (!soloContorno) {
      final relleno =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  claro
                      ? [Colors.white.withValues(alpha: .95), GColores.primarioSuave]
                      : [GColores.superficie, GColores.superficieAlt],
            ).createShader(Offset.zero & s);
      canvas.drawPath(cuerpo, relleno);

      // Vetas moradas de la cáscara (variedades Chino Morado / Napurí)
      final veta =
          Paint()
            ..color = (claro ? GColores.acento : GColores.primario).withValues(alpha: .28 * opacidad)
            ..style = PaintingStyle.fill;
      canvas.save();
      canvas.clipPath(cuerpo);
      for (final x in [.30, .5, .70]) {
        final v =
            Path()
              ..moveTo(p(x, .30).dx, p(x, .30).dy)
              ..quadraticBezierTo(p(x + (x - .5) * .6, .62).dx, p(x, .62).dy, p(x, .96).dx, p(x, .96).dy)
              ..lineTo(p(x + .06, .96).dx, p(x + .06, .96).dy)
              ..quadraticBezierTo(
                p(x + .06 + (x - .5) * .6, .62).dx,
                p(x, .62).dy,
                p(x + .03, .30).dx,
                p(x + .03, .30).dy,
              )
              ..close();
        canvas.drawPath(v, veta);
      }
      canvas.restore();
    }

    canvas.drawPath(cuerpo, linea);

    // Divisiones de los dientes
    final dientes =
        Path()
          ..moveTo(p(.5, .30).dx, p(.5, .30).dy)
          ..quadraticBezierTo(p(.53, .62).dx, p(.53, .62).dy, p(.5, .93).dx, p(.5, .93).dy)
          ..moveTo(p(.45, .30).dx, p(.45, .30).dy)
          ..quadraticBezierTo(p(.22, .56).dx, p(.22, .56).dy, p(.32, .90).dx, p(.32, .90).dy)
          ..moveTo(p(.55, .30).dx, p(.55, .30).dy)
          ..quadraticBezierTo(p(.78, .56).dx, p(.78, .56).dy, p(.68, .90).dx, p(.68, .90).dy);
    canvas.drawPath(dientes, linea..strokeWidth = math.max(1, w * .03));

    // Tallo (verde) y raíces
    final tallo =
        Paint()
          ..color = (claro ? GColores.acento : GColores.secundario).withValues(alpha: opacidad)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * .045)
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(.5, .10), p(.5, .02), tallo);
    canvas.drawLine(p(.5, .05), p(.58, .0), tallo);
    for (final dx in [-.08, 0.0, .08]) {
      canvas.drawLine(p(.5 + dx * .6, .95), p(.5 + dx, 1.0), linea..strokeWidth = math.max(1, w * .025));
    }
  }

  @override
  bool shouldRepaint(covariant _AjoPainter old) => old.claro != claro || old.opacidad != opacidad;
}

/// Logotipo: sello + nombre.
class GarlicWordmark extends StatelessWidget {
  const GarlicWordmark({super.key, this.claro = false, this.compacto = false});

  final bool claro;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final color = claro ? Colors.white : GColores.primario;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GarlicMark(size: compacto ? 28 : 34, claro: claro),
        const SizedBox(width: GEspacio.s),
        Text(
          'garlic',
          style: TextStyle(
            fontFamily: GTipo.titulos,
            fontWeight: FontWeight.w800,
            fontSize: compacto ? 22 : 26,
            letterSpacing: -0.8,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Fondo de encabezado: morado profundo con patrón sutil de ajos.
class FondoMarca extends StatelessWidget {
  const FondoMarca({super.key, required this.child, this.radioInferior = GRadio.panel});

  final Widget child;
  final double radioInferior;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(radioInferior)),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GColores.primario, GColores.primarioProfundo],
        ),
      ),
      child: CustomPaint(painter: _PatronPainter(), child: child),
    ),
  );
}

class _PatronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const paso = 74.0;
    final ajo = _AjoPainter(claro: true, soloContorno: true, opacidad: .07);
    var fila = 0;
    for (var y = -20.0; y < size.height + paso; y += paso * .8, fila++) {
      for (var x = (fila.isEven ? 0.0 : paso / 2) - 20; x < size.width + paso; x += paso) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(fila.isEven ? -.25 : .2);
        ajo.paint(canvas, const Size.square(30));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
