import 'package:flutter/widgets.dart';

/// Clases de ancho de ventana (flutter-build-responsive-layout): se decide por el espacio
/// disponible, nunca por "tipo de dispositivo". Una tablet en ventana dividida puede ser compacta.
enum AnchoVentana {
  /// < 600: celular. Barra de navegación inferior, una columna.
  compacto,

  /// 600–1024: tablet / ventana mediana. Riel de navegación, grillas de 2 columnas.
  medio,

  /// > 1024: laptop / escritorio. Sidebar, paneles lado a lado, dashboards.
  expandido;

  static const limiteMedio = 600.0;
  static const limiteExpandido = 1024.0;

  static AnchoVentana de(double ancho) =>
      ancho < limiteMedio
          ? compacto
          : ancho < limiteExpandido
          ? medio
          : expandido;

  static AnchoVentana of(BuildContext context) => de(MediaQuery.sizeOf(context).width);

  bool get esCompacto => this == compacto;
  bool get esExpandido => this == expandido;
}
