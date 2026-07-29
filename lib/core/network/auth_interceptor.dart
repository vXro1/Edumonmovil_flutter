import 'package:dio/dio.dart';

/// Interceptor de refresh — BLUEPRINT.md FASE 11.4.
/// authController.js real usa sesión por cookies httpOnly (access_token +
/// refresh_token con rotación), no un JWT en el body — el CookieManager de
/// Dio persiste y reenvía esas cookies solo, no hay Authorization header que
/// armar a mano. Ante un 401 (access_token vencido, code: TOKEN_EXPIRED) se
/// llama a POST /auth/refresh (usa la cookie refresh_token) y se reintenta la
/// request original una sola vez. El logout global solo se fuerza si el
/// refresh en sí falla (refresh_token inválido/vencido = sesión terminada);
/// si el refresh funciona pero la request reintentada igual devuelve 401,
/// el error se deja pasar tal cual al llamador — es un problema de esa ruta
/// puntual, no evidencia de que la sesión expiró.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required this.refreshDio,
    required this.retryDio,
    required this.onUnauthorized,
  });

  final Dio refreshDio;
  final Dio retryDio;
  final void Function() onUnauthorized;

  static const _exemptPaths = ['/auth/login', '/auth/register', '/auth/refresh', '/auth/logout'];

  bool _isExempt(String path) => _exemptPaths.any(path.contains);

  Future<void>? _refreshing;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (err.response?.statusCode != 401 || _isExempt(err.requestOptions.path) || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      // Coalesce refresh calls concurrentes — el backend rota el refresh
      // token, así que dos llamadas simultáneas invalidarían la sesión de la otra.
      await (_refreshing ??= refreshDio.post('/auth/refresh').then((_) {}));
      _refreshing = null;
    } catch (_) {
      // El refresh_token en sí es inválido/venció — acá sí la sesión
      // terminó de verdad.
      _refreshing = null;
      onUnauthorized();
      handler.next(err);
      return;
    }

    try {
      final options = err.requestOptions..extra['retried'] = true;
      final response = await retryDio.fetch(options);
      handler.resolve(response);
    } catch (retryError) {
      // El refresh funcionó (la sesión es válida) pero la request original
      // igual devolvió 401 — es un problema puntual de esa ruta/endpoint,
      // no de la sesión. No forzamos un logout global por esto: ej.
      // notificacionController.js real devuelve 401 "Usuario no autenticado"
      // ante cualquier fallo interno de middleware, sin que eso signifique
      // que la sesión del usuario expiró, y no tiene sentido sacarlo de
      // toda la app por un endpoint puntual roto.
      handler.next(retryError is DioException ? retryError : err);
    }
  }
}
