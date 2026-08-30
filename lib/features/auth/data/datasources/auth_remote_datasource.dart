import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/perfil_activo_model.dart';
import '../models/user_model.dart';

class LoginResponse {
  const LoginResponse({required this.user, required this.primerInicioSesion});

  final UserModel user;
  final bool primerInicioSesion;
}

/// Data source remoto — BLUEPRINT.md FASE 10.1.
/// authController.js real: login/register ya no devuelven un "token" en el
/// body — la sesión viaja en cookies httpOnly (access_token/refresh_token)
/// que el CookieManager de Dio maneja solo (ver core/network/api_client.dart).
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

  /// getProfile real devuelve `user` y, junto a él, `perfilActivo` — el
  /// perfil familiar (titular o secundario) que está activo en esta sesión
  /// (ver seleccionarPerfil en perfilFamiliarController.js). Antes acá se
  /// descartaba `perfilActivo` por completo, así que no había forma de saber
  /// qué perfil estaba seleccionado sin volver a listar /perfiles.
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
      // Best-effort — BLUEPRINT.md FASE 10.1 (logout es best-effort en el backend).
    }
  }

  /// logoutAll real (authRoutes.js: POST /auth/logout-all) revoca TODOS los
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

  // Antes: mandaba `telefono` tal cual lo tipeaba el usuario, sin `+57`.
  // normalizarTelefono() del backend espera/produce el formato con
  // prefijo (igual que en login/register), así que sin el `+57` no
  // encontraba al usuario en la BD — el endpoint respondía 200 genérico
  // igual (anti-enumeración) pero nunca mandaba el WhatsApp de verdad.
  Future<void> forgotPasswordByPhone(String telefono) =>
      _post('/auth/forgot-password-phone', {'telefono': '+57$telefono'});

  Future<void> resetPasswordByEmail({
    required String correo,
    required String codigo,
    required String contrasenaNueva,
  }) => _post('/auth/reset-password', {
    'correo': correo,
    'codigo': codigo,
    // authController.js resetPassword real: destructura "contraseñaNueva" (con ñ),
    // igual que el de teléfono — el blueprint lo documentó sin ñ para este, era incorrecto.
    'contraseñaNueva': contrasenaNueva,
  });

  // Mismo fix que forgotPasswordByPhone: sin el +57 el backend no
  // encuentra al usuario con resetPasswordToken y falla en silencio.
  Future<void> resetPasswordByPhone({
    required String telefono,
    required String codigo,
    required String contrasenaNueva,
  }) => _post('/auth/reset-password-phone', {
    'telefono': '+57$telefono',
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