import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';

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
    connectTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(seconds: 45),
    headers: {'Accept': 'application/json'},
    extra: const {'withCredentials': true},
  );
}
