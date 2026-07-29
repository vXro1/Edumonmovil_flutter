import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía de marca.
/// Encabezados/Display: Fredoka. Cuerpo/formularios/botones: Poppins.
class AppTypography {
  const AppTypography._();

  static TextStyle _fredoka({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    required Color color,
  }) {
    return GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _poppins({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    required Color color,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// [textColor]/[mutedColor] permiten generar la tabla para modo claro u
  /// oscuro sin duplicar toda la definición de estilos.
  static TextTheme textTheme({
    Color textColor = AppColors.textPrimary,
    Color mutedColor = AppColors.textMuted,
  }) {
    return TextTheme(
      displayLarge: _fredoka(size: 72, weight: FontWeight.w700, height: 1.15, color: textColor),
      displayMedium: _fredoka(size: 60, weight: FontWeight.w700, height: 1.15, color: textColor),
      displaySmall: _fredoka(size: 48, weight: FontWeight.w600, height: 1.15, color: textColor),
      headlineLarge: _fredoka(size: 36, weight: FontWeight.w600, height: 1.3, color: textColor),
      headlineMedium: _fredoka(size: 30, weight: FontWeight.w600, height: 1.3, color: textColor),
      headlineSmall: _fredoka(size: 24, weight: FontWeight.w600, height: 1.3, color: textColor),
      titleLarge: _fredoka(size: 20, weight: FontWeight.w600, height: 1.3, color: textColor),
      titleMedium: _poppins(size: 18, weight: FontWeight.w600, height: 1.5, color: textColor),
      titleSmall: _poppins(size: 16, weight: FontWeight.w600, height: 1.5, color: textColor),
      bodyLarge: _poppins(size: 18, weight: FontWeight.w400, height: 1.5, color: textColor),
      bodyMedium: _poppins(size: 16, weight: FontWeight.w400, height: 1.5, color: textColor),
      bodySmall: _poppins(size: 14, weight: FontWeight.w400, height: 1.5, color: mutedColor),
      labelLarge: _poppins(size: 16, weight: FontWeight.w600, height: 1.3, color: textColor),
      labelMedium: _poppins(size: 12, weight: FontWeight.w600, height: 1.3, color: textColor),
      labelSmall: _poppins(size: 10, weight: FontWeight.w600, height: 1.3, letterSpacing: 0.06, color: textColor),
    );
  }
}
