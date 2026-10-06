import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/user_activity_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> updateModoOscuro(bool modoOscuro) async {
    try {
      await _dio.patch('/users/me/modo-oscuro', data: {'modoOscuro': modoOscuro});
    } on DioException {
      // Best-effort.
    }
  }

  /// updateFcmToken (userRoutes.js: PUT /users/me/fcm-token) — registra
  /// el token del dispositivo para que notificacionService.js pueda mandar
  /// push reales vía FCMStrategy (admin.messaging().send) además de por
  /// WebSocket. Best-effort: si falla (sin red, Firebase no configurado
  /// todavía en este dispositivo) no debe interrumpir el login/arranque de
  /// la app por un canal de notificación que es best-effort en el backend
  /// también (ver notificacionService.js: enviarFCM nunca revienta el resto
  /// de canales si falla).
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.put('/users/me/fcm-token', data: {'fcmToken': fcmToken});
    } on DioException {
      // Best-effort.
    }
  }

  Future<List<String>> fetchDefaultAvatars() async {
    try {
      final response = await _dio.get('/users/fotos-predeterminadas');
      final data = response.data;
      // getFotosPredeterminadas devuelve {fotos: [{url, publicId, nombre},...]}
      // — objetos, no strings sueltos. Y desde la migración a almacenamiento
      // local, "url" es una ruta relativa ("/static/avatares/...") que hay
      // que resolver contra el origen del backend.
      final rawList = data is Map ? data['fotos'] as List? : null;
      return (rawList ?? const [])
          .whereType<Map>()
          .map((e) => Env.resolveUrl(e['url']?.toString()))
          .whereType<String>()
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> selectDefaultAvatar(String avatarUrl) async {
    try {
      await _dio.put('/users/me/foto-perfil', data: {'fotoPredeterminadaUrl': avatarUrl});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
  }) async {
    try {
      await _dio.put(
        '/users/me/profile',
        data: {
          'nombre': ?nombre,
          'apellido': ?apellido,
          'correo': ?correo,
          'telefono': ?telefono,
        },
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // authController.js changePassword no reemite cookies de sesión — solo
  // cambia la contraseña y pone primerInicioSesion:false en BD. El
  // access_token/refresh_token vigentes siguen siendo válidos tal cual.
  Future<void> changePassword({required String contrasenaActual, required String contrasenaNueva}) async {
    try {
      await _dio.post(
        '/auth/change-password',
        // authController.js changePassword: destructura "contraseñaActual"/
        // "contraseñaNueva" (con ñ).
        data: {'contraseñaActual': contrasenaActual, 'contraseñaNueva': contrasenaNueva},
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// getUltimasSesiones: para no-superadmin devuelve {ultimoAcceso},
  /// para superadmin devuelve {sesiones: [...], pagination: {...}} con la
  /// actividad de TODOS los usuarios — nunca las dos formas a la vez.
  Future<({DateTime? ultimoAcceso, List<UserActivityModel> usersActivity, bool hasMore, bool isAdminView})>
  fetchSessionsInfo({required int page, required int limit}) async {
    try {
      final response = await _dio.get('/users/sesiones/ultimas', queryParameters: {'page': page, 'limit': limit});
      final data = response.data as Map<String, dynamic>;

      // "sesiones" solo está presente en la rama superadmin de getUltimasSesiones;
      // se usa como discriminante explícito en vez de inferir por nulls (ambos
      // ultimoAcceso y la lista pueden estar "vacíos" legítimamente).
      if (data.containsKey('sesiones')) {
        final items = (data['sesiones'] as List)
            .map((e) => UserActivityModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = data['pagination'] as Map<String, dynamic>?;
        return (
          ultimoAcceso: null,
          usersActivity: items,
          hasMore: pagination?['hasNextPage'] == true,
          isAdminView: true,
        );
      }

      final ultimoAcceso = data['ultimoAcceso'] != null ? DateTime.tryParse(data['ultimoAcceso'].toString()) : null;
      return (ultimoAcceso: ultimoAcceso, usersActivity: const <UserActivityModel>[], hasMore: false, isAdminView: false);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
