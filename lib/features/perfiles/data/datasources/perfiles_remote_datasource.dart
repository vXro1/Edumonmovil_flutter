import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/perfil_model.dart';

/// Data source remoto — BLUEPRINT.md FASE 10.8.
/// (⚠️) No vimos perfilFamiliarController.js real — shapes inferidos del
/// blueprint.
class PerfilesRemoteDataSource {
  const PerfilesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PerfilModel>> fetchPerfiles() async {
    try {
      final response = await _dio.get('/perfiles');
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['perfiles'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => PerfilModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PerfilModel> createPerfil({required String nombre, String? avatarUrl}) async {
    try {
      final response = await _dio.post(
        '/perfiles',
        data: {'nombre': nombre, 'avatarUrl': ?avatarUrl},
      );
      final data = response.data;
      final json = data is Map ? (data['perfil'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return PerfilModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PerfilModel> updatePerfil({required String id, String? nombre, String? avatarUrl}) async {
    try {
      final response = await _dio.put(
        '/perfiles/$id',
        data: {'nombre': ?nombre, 'avatarUrl': ?avatarUrl},
      );
      final data = response.data;
      final json = data is Map ? (data['perfil'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return PerfilModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deletePerfil(String id) async {
    try {
      await _dio.delete('/perfiles/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> seleccionarPerfil(String perfilId) async {
    try {
      await _dio.post('/perfiles/seleccionar', data: {'perfilId': perfilId});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.post('/perfiles/fcm-token', data: {'fcmToken': fcmToken});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
