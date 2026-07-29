import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sombras — BLUEPRINT.md FASE 2.6.
/// Las sombras "3D" de botones son offset sólido (sin blur), para el efecto
/// de "hundimiento" al presionar (ver EdumonButton).
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 8), blurRadius: 16),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 12),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 12), blurRadius: 24),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 16), blurRadius: 64),
  ];

  /// Sombra 3D sólida (sin blur) de un botón en reposo, por color base.
  static List<BoxShadow> button3d(Color base, {double offset = 5}) => [
    BoxShadow(color: base, offset: Offset(0, offset)),
  ];

  static List<BoxShadow> buttonPrimary({double offset = 5}) =>
      button3d(AppColors.shadowBtnPrimary, offset: offset);
  static List<BoxShadow> buttonSuccess({double offset = 5}) =>
      button3d(AppColors.shadowBtnSuccess, offset: offset);
  static List<BoxShadow> buttonDanger({double offset = 5}) =>
      button3d(AppColors.shadowBtnDanger, offset: offset);
  static List<BoxShadow> buttonWarning({double offset = 5}) =>
      button3d(AppColors.shadowBtnWarning, offset: offset);
}
