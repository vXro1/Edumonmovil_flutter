import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';

/// (⚠️) No vimos buzonController.js real para el endpoint de creación
/// pública — se infiere `POST /buzon` por convención con el resto de la API
/// (mismo patrón: GET /recurso lista, POST /recurso crea) y porque
/// BuzonRepository ya documentaba que ese POST público existe en la landing
/// web real, solo que no vive en esta app. Verificar contra el controller
/// real si el formulario devuelve 404/405.
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
