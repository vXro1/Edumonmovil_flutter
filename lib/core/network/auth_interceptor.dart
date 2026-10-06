import 'package:dio/dio.dart';

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
      final data = options.data;
      if (data is FormData) options.data = data.clone();
      final response = await retryDio.fetch(options);
      handler.resolve(response);
    } catch (retryError) {
      handler.next(retryError is DioException ? retryError : err);
    }
  }
}
