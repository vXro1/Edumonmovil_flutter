import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/institucion_model.dart';

/// Data source remoto — shapes verificados contra institucionController.js real.
class InstitucionesRemoteDataSource {
  const InstitucionesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<InstitucionModel>> fetchInstituciones() async {
    try {
      final response = await _dio.get('/instituciones');
      final data = response.data;
      final rawList = data is List
          ? data
          : (data is Map ? (data['instituciones'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => InstitucionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<InstitucionModel> createInstitucion({
    required String nombre,
    required String nit,
    required String direccion,
    required String telefono,
    required String correo,
    required String adminNombre,
    required String adminApellido,
    required String adminCedula,
    required String adminCorreo,
    required String adminTelefono,
  }) async {
    try {
      final response = await _dio.post(
        '/instituciones',
        data: {
          'nombre': nombre,
          'nit': nit,
          'direccion': direccion,
          'telefono': telefono,
          'correo': correo,
          'adminNombre': adminNombre,
          'adminApellido': adminApellido,
          'adminCedula': adminCedula,
          'adminCorreo': adminCorreo,
          'adminTelefono': adminTelefono,
        },
      );
      final data = response.data;
      final json = data is Map ? (data['institucion'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return InstitucionModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<InstitucionModel> updateInstitucion({
    required String id,
    required String nombre,
    required String direccion,
    required String telefono,
    required String correo,
  }) async {
    try {
      final response = await _dio.put(
        '/instituciones/$id',
        data: {'nombre': nombre, 'direccion': direccion, 'telefono': telefono, 'correo': correo},
      );
      final data = response.data;
      final json = data is Map ? (data['institucion'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return InstitucionModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
