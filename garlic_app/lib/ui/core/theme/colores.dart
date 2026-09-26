import 'package:flutter/material.dart';

import '../../../domain/models/evaluacion.dart';
import '../../../domain/models/sync.dart';

/// Tokens de color de la marca "Morado ajo + marfil" (design-system/garlic/MASTER.md).
/// Los componentes usan estos tokens o el ColorScheme; nunca hex sueltos.
abstract final class GColores {
  // Marca
  static const primario = Color(0xFF4A2560); // morado ajo
  static const primarioProfundo = Color(0xFF321640);
  static const primarioSuave = Color(0xFFEFE6F3);
  static const secundario = Color(0xFF5F7A2E); // verde tallo
  static const secundarioSuave = Color(0xFFE8EFD9);
  static const acento = Color(0xFFE0A030); // ámbar cosecha
  static const acentoSuave = Color(0xFFFBEFD6);

  // Superficies
  static const fondo = Color(0xFFFAF6EE); // marfil
  static const superficie = Color(0xFFFFFFFF);
  static const superficieAlt = Color(0xFFF1EADB); // papel de cáscara
  static const borde = Color(0xFFE2D8C6);

  // Texto
  static const tinta = Color(0xFF1E1A22);
  static const tintaSuave = Color(0xFF6B6270);

  // Estados
  static const error = Color(0xFFC2412D);
  static const errorSuave = Color(0xFFF8E3DE);
  static const advertencia = Color(0xFFB8740F);
  static const advertenciaSuave = Color(0xFFFBEBD2);
  static const info = Color(0xFF2F6FA3);
  static const exito = Color(0xFF3F8F5A);
  static const exitoSuave = Color(0xFFE2F1E6);

  static Color humedad(NivelHumedad n) => switch (n) {
    NivelHumedad.baja => exito,
    NivelHumedad.media => advertencia,
    NivelHumedad.alta => error,
  };

  static Color humedadSuave(NivelHumedad n) => switch (n) {
    NivelHumedad.baja => exitoSuave,
    NivelHumedad.media => advertenciaSuave,
    NivelHumedad.alta => errorSuave,
  };

  static Color sync(SyncState s) => switch (s) {
    SyncState.sincronizado => secundario,
    SyncState.pendiente => advertencia,
    SyncState.error => error,
  };

  /// Paleta para gráficos (distinguible también en escala de grises).
  static const grafico = [primario, acento, secundario, Color(0xFF9B6BB0), Color(0xFF2F6FA3), Color(0xFFB85C38)];
}
