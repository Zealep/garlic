import 'package:flutter/material.dart';

import '../../../domain/models/sync.dart';

/// Tokens de color de la marca Agroexportadora Guadalupe (verde + naranja sobre marfil, tomados de su web).
/// Ver design-system/garlic/MASTER.md. Los componentes usan estos tokens o el ColorScheme; nunca hex sueltos.
abstract final class GColores {
  // Marca
  static const primario = Color(0xFF10662F); // verde Guadalupe
  static const primarioProfundo = Color(0xFF0B4521);
  static const primarioSuave = Color(0xFFE8F2EA);
  static const secundario = Color(0xFF2E8B4E); // verde hoja (estados "bien": sincronizado, sin humedad)
  static const secundarioSuave = Color(0xFFDDEFE2);
  static const acento = Color(0xFFEC9A2D); // naranja cosecha
  static const acentoSuave = Color(0xFFFCEBD3);

  // Superficies
  static const fondo = Color(0xFFF7F4EC); // marfil
  static const superficie = Color(0xFFFFFFFF);
  static const superficieAlt = Color(0xFFEFEBDF);
  static const borde = Color(0xFFE2E0D6);

  // Texto
  static const tinta = Color(0xFF1D2620);
  static const tintaSuave = Color(0xFF55605A);

  // Estados
  static const error = Color(0xFFB42318);
  static const errorSuave = Color(0xFFF9E1DD);
  static const advertencia = Color(0xFFB8740F);
  static const advertenciaSuave = Color(0xFFFBEBD2);
  static const info = Color(0xFF2F6FA3);
  static const exito = Color(0xFF2E8B4E);
  static const exitoSuave = Color(0xFFE2F1E6);

  static Color sync(SyncState s) => switch (s) {
    SyncState.sincronizado => secundario,
    SyncState.pendiente => advertencia,
    SyncState.error => error,
  };

  /// Paleta para gráficos (distinguible también en escala de grises).
  static const grafico = [primario, acento, Color(0xFF8A5A2B), Color(0xFF7FB77E), Color(0xFF2F6FA3), Color(0xFFB85C38)];
}
