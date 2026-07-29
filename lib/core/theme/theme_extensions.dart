import 'package:flutter/material.dart';

/// Atajo usado en toda la app para resolver colores claro/oscuro sin repetir
/// `Theme.of(context).brightness == Brightness.dark` en cada pantalla.
extension ThemeBrightnessX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
