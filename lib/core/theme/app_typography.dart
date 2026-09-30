import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía de marca — Nunito en toda la app (misma familia única que la
/// web desde su "cambio tipográfico", antes Fredoka + Poppins acá).
/// Solo 3 pesos: Black para títulos/encabezados, Regular para texto normal,
/// Light para texto secundario (bodySmall, ya pintado con mutedColor).
class AppTypography {
  const AppTypography._();

  static TextStyle _nunito({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    required Color color,
  }) {
    return GoogleFonts.nunito(
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
      displayLarge: _nunito(size: 72, weight: FontWeight.w900, height: 1.15, color: textColor),
      displayMedium: _nunito(size: 60, weight: FontWeight.w900, height: 1.15, color: textColor),
      displaySmall: _nunito(size: 48, weight: FontWeight.w900, height: 1.15, color: textColor),
      headlineLarge: _nunito(size: 36, weight: FontWeight.w900, height: 1.3, color: textColor),
      headlineMedium: _nunito(size: 30, weight: FontWeight.w900, height: 1.3, color: textColor),
      headlineSmall: _nunito(size: 24, weight: FontWeight.w900, height: 1.3, color: textColor),
      titleLarge: _nunito(size: 20, weight: FontWeight.w900, height: 1.3, color: textColor),
      titleMedium: _nunito(size: 18, weight: FontWeight.w400, height: 1.5, color: textColor),
      titleSmall: _nunito(size: 16, weight: FontWeight.w400, height: 1.5, color: textColor),
      bodyLarge: _nunito(size: 18, weight: FontWeight.w400, height: 1.5, color: textColor),
      bodyMedium: _nunito(size: 16, weight: FontWeight.w400, height: 1.5, color: textColor),
      bodySmall: _nunito(size: 14, weight: FontWeight.w300, height: 1.5, color: mutedColor),
      labelLarge: _nunito(size: 16, weight: FontWeight.w400, height: 1.3, color: textColor),
      labelMedium: _nunito(size: 12, weight: FontWeight.w400, height: 1.3, color: textColor),
      labelSmall: _nunito(size: 10, weight: FontWeight.w400, height: 1.3, letterSpacing: 0.06, color: textColor),
    );
  }
}
