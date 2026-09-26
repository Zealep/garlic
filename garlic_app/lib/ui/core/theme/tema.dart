import 'package:flutter/material.dart';

import 'colores.dart';

/// Espaciado y radios del design system.
abstract final class GEspacio {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

abstract final class GRadio {
  static const chico = 12.0;
  static const tarjeta = 18.0;
  static const panel = 28.0;
}

/// Tipografías: Bricolage Grotesque (títulos, cifras) + Inter (texto, formularios).
abstract final class GTipo {
  static const titulos = 'Bricolage';
  static const texto = 'Inter';

  /// Números alineados en columnas (porcentajes, KPIs).
  static const tabular = [FontFeature.tabularFigures()];

  static TextStyle cifra(double size, {Color color = GColores.tinta, FontWeight weight = FontWeight.w700}) => TextStyle(
    fontFamily: titulos,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.05,
    fontFeatures: tabular,
    letterSpacing: -0.5,
  );
}

abstract final class TemaGarlic {
  static ThemeData claro() {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: GColores.primario,
      onPrimary: Colors.white,
      primaryContainer: GColores.primarioSuave,
      onPrimaryContainer: GColores.primarioProfundo,
      secondary: GColores.secundario,
      onSecondary: Colors.white,
      secondaryContainer: GColores.secundarioSuave,
      onSecondaryContainer: Color(0xFF2E3D14),
      tertiary: GColores.acento,
      onTertiary: GColores.tinta,
      tertiaryContainer: GColores.acentoSuave,
      onTertiaryContainer: Color(0xFF5A3A00),
      error: GColores.error,
      onError: Colors.white,
      errorContainer: GColores.errorSuave,
      onErrorContainer: Color(0xFF6B1A0E),
      surface: GColores.fondo,
      onSurface: GColores.tinta,
      onSurfaceVariant: GColores.tintaSuave,
      surfaceContainerLowest: GColores.superficie,
      surfaceContainerLow: GColores.superficie,
      surfaceContainer: GColores.superficie,
      surfaceContainerHigh: GColores.superficieAlt,
      surfaceContainerHighest: GColores.superficieAlt,
      outline: GColores.borde,
      outlineVariant: GColores.borde,
      shadow: GColores.primarioProfundo,
      inverseSurface: GColores.primarioProfundo,
      onInverseSurface: Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: esquema, fontFamily: GTipo.texto);
    final textos = base.textTheme.copyWith(
      displaySmall: _t(36, FontWeight.w800, titulos: true),
      headlineMedium: _t(28, FontWeight.w700, titulos: true),
      headlineSmall: _t(24, FontWeight.w700, titulos: true),
      titleLarge: _t(20, FontWeight.w700, titulos: true),
      titleMedium: _t(16, FontWeight.w600),
      titleSmall: _t(14, FontWeight.w600),
      bodyLarge: _t(16, FontWeight.w400, alto: 1.45),
      bodyMedium: _t(14, FontWeight.w400, alto: 1.45),
      bodySmall: _t(12.5, FontWeight.w400, color: GColores.tintaSuave, alto: 1.4),
      labelLarge: _t(15, FontWeight.w600),
      labelMedium: _t(13, FontWeight.w600),
      labelSmall: _t(11.5, FontWeight.w600, espaciado: 0.4),
    );

    final bordeInput = OutlineInputBorder(
      borderRadius: BorderRadius.circular(GRadio.chico),
      borderSide: const BorderSide(color: GColores.borde),
    );

    return base.copyWith(
      scaffoldBackgroundColor: GColores.fondo,
      textTheme: textos,
      appBarTheme: AppBarTheme(
        backgroundColor: GColores.fondo,
        foregroundColor: GColores.tinta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textos.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: GColores.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GRadio.tarjeta),
          side: const BorderSide(color: GColores.borde),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GColores.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: bordeInput,
        enabledBorder: bordeInput,
        focusedBorder: bordeInput.copyWith(borderSide: const BorderSide(color: GColores.primario, width: 2)),
        errorBorder: bordeInput.copyWith(borderSide: const BorderSide(color: GColores.error)),
        focusedErrorBorder: bordeInput.copyWith(borderSide: const BorderSide(color: GColores.error, width: 2)),
        labelStyle: const TextStyle(color: GColores.tintaSuave),
        floatingLabelStyle: const TextStyle(color: GColores.primario, fontWeight: FontWeight.w600),
        helperMaxLines: 2,
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadio.chico + 2)),
          textStyle: textos.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          foregroundColor: GColores.primario,
          side: const BorderSide(color: GColores.borde, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadio.chico + 2)),
          textStyle: textos.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: GColores.primario,
          textStyle: textos.labelLarge,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: GColores.superficie,
        selectedColor: GColores.primarioSuave,
        side: const BorderSide(color: GColores.borde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadio.chico)),
        labelStyle: textos.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        showCheckmark: true,
        checkmarkColor: GColores.primario,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          textStyle: WidgetStatePropertyAll(textos.labelMedium),
          side: const WidgetStatePropertyAll(BorderSide(color: GColores.borde)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: GColores.superficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: GColores.primarioSuave,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textos.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected) ? GColores.primario : GColores.tintaSuave,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: GColores.superficie,
        indicatorColor: GColores.primarioSuave,
        selectedLabelTextStyle: textos.labelMedium!.copyWith(color: GColores.primario),
        unselectedLabelTextStyle: textos.labelMedium!.copyWith(color: GColores.tintaSuave),
      ),
      dividerTheme: const DividerThemeData(color: GColores.borde, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GColores.primarioProfundo,
        contentTextStyle: textos.bodyMedium!.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadio.chico)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GColores.acento,
        foregroundColor: GColores.tinta,
        elevation: 2,
        extendedTextStyle: TextStyle(fontFamily: GTipo.texto, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: GColores.secundario,
        inactiveTrackColor: GColores.acentoSuave,
        thumbColor: GColores.primario,
        trackHeight: 8,
        overlayColor: GColores.primario.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: GColores.primario),
    );
  }

  static TextStyle _t(
    double size,
    FontWeight w, {
    bool titulos = false,
    Color color = GColores.tinta,
    double? alto,
    double? espaciado,
  }) => TextStyle(
    fontFamily: titulos ? GTipo.titulos : GTipo.texto,
    fontSize: size,
    fontWeight: w,
    color: color,
    height: alto,
    letterSpacing: espaciado ?? (titulos ? -0.3 : 0),
  );
}
