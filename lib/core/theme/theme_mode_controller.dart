import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'edumon_theme_mode';

/// Preferencia de tema (Claro/Oscuro/Sistema) elegida manualmente en
/// Configuración. Persiste en disco para sobrevivir reinicios de la app;
/// por defecto sigue el tema del sistema operativo.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final restored = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (restored != null) state = restored;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
