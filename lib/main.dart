import 'package:cookie_jar/cookie_jar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/network/cookie_jar_provider.dart';
import 'core/notifications/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notificaciones push (FCM) — best-effort a propósito: hasta que
  // android/app/google-services.json exista de verdad (ver fcm_service.dart),
  // Firebase.initializeApp() lanza y esto queda deshabilitado sin tumbar el
  // resto de la app, mismo criterio que ya usa el backend para este canal.
  // El resto de la integración (canal de Android, pedir permiso, registrar
  // token) se hace desde AuthController una vez hay sesión — acá solo va lo
  // que Firebase exige registrar temprano, antes de runApp.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[FCM] Firebase.initializeApp() no disponible: $e');
  }

  // La app no debe depender de la red para renderizar texto: si no hay
  // internet (wifi de colegio inestable, primer arranque sin conexión),
  // google_fonts cae al font del sistema en vez de intentar descargar
  // Nunito desde fonts.gstatic.com y tirar una excepción. Por eso Nunito
  // viene embebido en assets/fonts/ (ver app_typography.dart).
  GoogleFonts.config.allowRuntimeFetching = false;

  //: es-CO como locale principal — DateFormat lo requiere
  // inicializado antes de formatear fechas con ese locale.
  await initializeDateFormatting('es_CO');

  final cookieJar = kIsWeb
      ? CookieJar()
      : PersistCookieJar(storage: FileStorage('${(await getApplicationSupportDirectory()).path}/.cookies'));

  runApp(
    ProviderScope(
      overrides: [cookieJarProvider.overrideWithValue(cookieJar)],
      child: const EdumonApp(),
    ),
  );
}
