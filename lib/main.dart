import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/network/cookie_jar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La app no debe depender de la red para renderizar texto: si no hay
  // internet (wifi de colegio inestable, primer arranque sin conexión),
  // google_fonts cae al font del sistema en vez de intentar descargar
  // Inter/Poppins desde fonts.gstatic.com y tirar una excepción.
  GoogleFonts.config.allowRuntimeFetching = false;

  // FASE 5.6: es-CO como locale principal — DateFormat lo requiere
  // inicializado antes de formatear fechas con ese locale.
  await initializeDateFormatting('es_CO');

  // authController.js real guarda la sesión en cookies httpOnly
  // (access_token + refresh_token) en vez de un JWT en el body — se necesita
  // un CookieJar persistente en disco para que la sesión sobreviva a
  // reinicios de la app, igual que hacía antes el token en secure storage.
  // En web no hay filesystem (path_provider no implementa
  // getApplicationSupportDirectory ahí), así que se usa un CookieJar en
  // memoria en su lugar — pero ahí es en gran parte vestigial: las cookies
  // httpOnly cross-origin nunca son legibles por JS/Dart, así que
  // dio_cookie_manager jamás las captura en web de todas formas. La sesión
  // real la persiste el propio navegador (Set-Cookie + `withCredentials`,
  // ver api_client.dart) de forma completamente independiente de este
  // CookieJar, así que sí sobrevive a un refresh de página mientras la
  // cookie del backend siga vigente. Este CookieJar en memoria solo evita
  // que la app intente tocar el filesystem (inexistente en el navegador) y
  // crashee en el primer frame.
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
