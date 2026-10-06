import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/perfil_model.dart';

class PerfilesRemoteDataSource {
  const PerfilesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({PerfilModel titular, List<PerfilModel> secundarios})> fetchPerfiles() async {
    try {
      final response = await _dio.get('/perfiles');
      final data = response.data as Map<String, dynamic>;
      final titularJson = data['titular'] as Map<String, dynamic>;
      final rawList = data['perfiles'] as List?;
      return (
        titular: PerfilModel.fromJson(titularJson, esTitularFallback: true),
        secundarios: (rawList ?? const []).map((e) => PerfilModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
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

  /// guardarFCMTokenPerfil guarda el token FCM POR PERFIL (cada
  /// PerfilFamiliar tiene su propio fcmToken) — sin [perfilId] el backend lo
  /// asigna siempre al titular, sin importar qué perfil esté activo en este
  /// dispositivo. `null`/omitido selecciona explícitamente al titular (mismo
  /// sentinel que usa seleccionarPerfil).
  Future<void> updateFcmToken(String fcmToken, {String? perfilId}) async {
    try {
      await _dio.post('/perfiles/fcm-token', data: {'fcmToken': fcmToken, 'perfilId': ?perfilId});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
