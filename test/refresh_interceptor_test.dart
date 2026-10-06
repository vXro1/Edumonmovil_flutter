import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:edumon_movil/core/network/auth_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adapter falso: la primera request a /eventos devuelve 401 (access_token
/// vencido), /auth/refresh responde 200 y el reintento devuelve 201. Lee el
/// cuerpo completo de cada request, igual que el adapter real, para que un
/// FormData reenviado sin clonar falle como en el dispositivo.
class _FakeAdapter implements HttpClientAdapter {
  int eventosCalls = 0;
  final bodies = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (requestStream != null) {
      final bytes = await requestStream.expand((c) => c).toList();
      bodies.add(String.fromCharCodes(bytes));
    }
    if (options.path.contains('/auth/refresh')) return ResponseBody.fromString('{}', 200, headers: _json);
    eventosCalls++;
    if (eventosCalls == 1) {
      return ResponseBody.fromString('{"message":"Token expirado","code":"TOKEN_EXPIRED"}', 401, headers: _json);
    }
    return ResponseBody.fromString('{"evento":{"_id":"1"}}', 201, headers: _json);
  }

  static const _json = {
    Headers.contentTypeHeader: ['application/json'],
  };

  @override
  void close({bool force = false}) {}
}

void main() {
  test('reintenta un POST multipart tras refrescar la sesión (FormData clonado)', () async {
    final adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
    var loggedOut = false;
    dio.interceptors.add(RefreshInterceptor(refreshDio: refreshDio, retryDio: dio, onUnauthorized: () => loggedOut = true));

    final formData = FormData.fromMap({
      'titulo': 'Reunion de padres',
      'cursosIds': '["abc"]',
      'adjunto': MultipartFile.fromBytes([1, 2, 3], filename: 'a.pdf'),
    });

    final response = await dio.post('/eventos', data: formData);

    expect(response.statusCode, 201);
    expect(adapter.eventosCalls, 2);
    expect(loggedOut, isFalse);
    // el reintento manda el mismo contenido que el envío original
    final eventoBodies = adapter.bodies.where((b) => b.contains('Reunion de padres')).toList();
    expect(eventoBodies, hasLength(2));
    expect(eventoBodies[1], eventoBodies[0]);
  });
}
