import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';

class BuzonPublicoRemoteDataSource {
  const BuzonPublicoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> enviarMensaje({
    required String nombre,
    required String correo,
    String? telefono,
    String? institucion,
    required String mensaje,
  }) async {
    try {
      await _dio.post(
        '/buzon',
        data: {
          'nombre': nombre,
          'correo': correo,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
          if (institucion != null && institucion.isNotEmpty) 'institucion': institucion,
          'mensaje': mensaje,
        },
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
