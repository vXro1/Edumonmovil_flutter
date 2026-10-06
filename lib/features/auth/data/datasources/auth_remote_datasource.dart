import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/perfil_activo_model.dart';
import '../models/user_model.dart';

class LoginResponse {
  const LoginResponse({required this.user, required this.primerInicioSesion});

  final UserModel user;
  final bool primerInicioSesion;
}

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResponse> login({required String telefono, required String contrasena}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'telefono': '+57$telefono', 'contraseña': contrasena},
      );
      final data = response.data as Map<String, dynamic>;
      return LoginResponse(
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        primerInicioSesion: data['primerInicioSesion'] == true,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<({UserModel user, PerfilActivoModel? perfilActivo})> fetchProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      final data = response.data as Map<String, dynamic>;
      final perfilActivoRaw = data['perfilActivo'];
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        perfilActivo: perfilActivoRaw is Map
            ? PerfilActivoModel.fromJson(perfilActivoRaw as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // Best-effort (logout es best-effort en el backend).
    }
  }

  /// logoutAll (authRoutes.js: POST /auth/logout-all) revoca TODOS los
  /// refresh tokens del usuario (todas las sesiones/dispositivos), no solo
  /// la actual, y limpia las cookies de esta sesión también.
  Future<void> logoutAll() async {
    try {
      await _dio.post('/auth/logout-all');
    } on DioException {
      // Best-effort, mismo criterio que logout().
    }
  }

  Future<void> forgotPasswordByEmail(String correo) => _post('/auth/forgot-password', {'correo': correo});

  Future<void> resetPasswordByEmail({
    required String correo,
    required String codigo,
    required String contrasenaNueva,
  }) => _post('/auth/reset-password', {
    'correo': correo,
    'codigo': codigo,
    'contraseñaNueva': contrasenaNueva,
  });

  Future<void> _post(String path, Map<String, dynamic> data) async {
    try {
      await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}