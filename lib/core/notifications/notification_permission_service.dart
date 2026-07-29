import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'edumon_notification_permission_requested';

/// Pide el permiso nativo de notificaciones (POST_NOTIFICATIONS en Android
/// 13+; permiso equivalente en iOS) una sola vez por instalación — no
/// vuelve a insistir en cada login si el usuario ya respondió, acepte o
/// rechace. Sin este permiso el sistema operativo no muestra ninguna
/// notificación aunque el backend la envíe.
Future<void> requestNotificationPermissionOnce() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_prefsKey) == true) return;
  try {
    await Permission.notification.request();
  } catch (_) {
    // Best-effort — no debe bloquear el login si la plataforma no soporta
    // el permiso (ej. web) o algo falla al pedirlo.
  }
  await prefs.setBool(_prefsKey, true);
}
