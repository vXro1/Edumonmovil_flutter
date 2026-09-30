import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP central — BLUEPRINT.md FASE 5.6 / FASE 10.
/// authController.js real usa cookies httpOnly para la sesión (ver
/// RefreshInterceptor) — el [cookieJar] debe ser un PersistCookieJar creado
/// una sola vez en main() para que la sesión sobreviva a reinicios de la app.
class ApiClient {
  ApiClient({
    required CookieJar cookieJar,
    required void Function() onUnauthorized,
  }) : dio = Dio(_baseOptions) {
    dio.interceptors.add(CookieManager(cookieJar));

    // Dio separado para /auth/refresh: comparte las mismas cookies pero no
    // lleva el RefreshInterceptor, para no reintentar recursivamente si el
    // propio refresh devuelve 401.
    final refreshDio = Dio(_baseOptions)..interceptors.add(CookieManager(cookieJar));

    dio.interceptors.add(
      RefreshInterceptor(refreshDio: refreshDio, retryDio: dio, onUnauthorized: onUnauthorized),
    );

    // Solo en debug: incluye el cuerpo de request/response (útil para ver el
    // mensaje real de un 400/401), pero nunca en release para no filtrar
    // credenciales/tokens en logs de producción. Sin el "pretty box" de
    // package:logger — una línea por evento es más legible y no inunda logcat.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          logPrint: (obj) => debugPrint('[HTTP] $obj'),
        ),
      );
    }
  }

  final Dio dio;

  static BaseOptions get _baseOptions => BaseOptions(
    baseUrl: Env.apiBaseUrl,
    // El backend ya no vive en Render (se movió a un despliegue Docker
    // propio en edumon.uniautonoma.edu.co), pero se deja este margen amplio
    // por si el hosting actual también tiene cold start o picos de latencia
    // — antes, con Render (plan free hibernaba tras inactividad y tardaba
    // 30-50s en despertar), 15s cortaba la espera antes de que respondiera.
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 45),
    headers: {'Accept': 'application/json'},
    // BUG REAL (login no funcionaba en web): las cookies httpOnly de sesión
    // vienen de un backend en otro origen (antes backend-edumon.onrender.com,
    // ahora edumon.uniautonoma.edu.co), y
    // el adaptador de Dio para navegador (dio_web_adapter) por defecto arma
    // el XHR con `withCredentials: false` — el navegador entonces IGNORA por
    // completo el `Set-Cookie` de la respuesta del login (nunca guarda la
    // sesión) y tampoco reenvía cookies existentes en requests siguientes.
    // El login "parecía" funcionar un instante porque el usuario sí llega en
    // el body de la respuesta, pero cualquier request protegido después caía
    // en 401 y terminaba en forceLogout(). `extra['withCredentials']` es la
    // forma de fijar esto sin importar el adapter de navegador directamente
    // (que no compila para Android/iOS) — en móvil esta clave simplemente se
    // ignora, ahí la sesión ya la maneja dio_cookie_manager + PersistCookieJar.
    extra: const {'withCredentials': true},
  );
}
