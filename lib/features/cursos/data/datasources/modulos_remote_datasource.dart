import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/modulo_model.dart';

/// Data source remoto — shapes verificados contra moduloController.js real.
class ModulosRemoteDataSource {
  const ModulosRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ModuloModel>> fetchModulos(String cursoId, {bool incluirInactivos = false}) async {
    try {
      final response = await _dio.get(
        '/modulos/curso/$cursoId',
        queryParameters: {if (incluirInactivos) 'incluirInactivos': 'true'},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['modulos'] as List).map((e) => ModuloModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ModuloModel> createModulo({required String cursoId, required String titulo, String? descripcion}) async {
    try {
      final response = await _dio.post(
        '/modulos',
        data: {'cursoId': cursoId, 'titulo': titulo, 'descripcion': ?descripcion},
      );
      final data = response.data as Map<String, dynamic>;
      return ModuloModel.fromJson(data['modulo'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ModuloModel> updateModulo({required String id, required String titulo, String? descripcion}) async {
    try {
      final response = await _dio.put(
        '/modulos/$id',
        data: {'titulo': titulo, 'descripcion': ?descripcion},
      );
      final data = response.data as Map<String, dynamic>;
      return ModuloModel.fromJson(data['modulo'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteModulo(String id) async {
    try {
      await _dio.delete('/modulos/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> restoreModulo(String id) async {
    try {
      await _dio.patch('/modulos/$id/restore');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
