import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/user_activity_model.dart';

/// Data source remoto para el Wizard de primer login y Sesiones activas.
/// Endpoints y shapes verificados contra userController.js/authController.js reales
/// (no contra el blueprint, que documentaba algunos de estos de forma distinta).
class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<String>> fetchDefaultAvatars() async {
    try {
      final response = await _dio.get('/users/fotos-predeterminadas');
      final data = response.data;
      // getFotosPredeterminadas real devuelve {fotos: [{url, publicId, nombre}, ...]}
      // — objetos, no strings sueltos.
      final rawList = data is Map ? data['fotos'] as List? : null;
      return (rawList ?? const [])
          .whereType<Map>()
          .map((e) => e['url']?.toString())
          .whereType<String>()
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// userController.js real: PUT /users/me/foto-perfil también acepta un
  /// archivo (multipart, campo "foto") para foto propia, pero esa opción no
  /// se expone en la app — solo avatares predeterminados (decisión de producto).
  Future<void> selectDefaultAvatar(String avatarUrl) async {
    try {
      await _dio.put('/users/me/foto-perfil', data: {'fotoPredeterminadaUrl': avatarUrl});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // userController.js real: PUT /users/:id (updateUser) ahora exige rol
  // administrador/superadmin — un padre/docente editando su PROPIO perfil ya
  // no puede usar esa ruta (403). El backend agregó updateOwnProfile
  // (whitelist nombre/apellido/correo/telefono, nunca rol/estado/institución,
  // el id sale siempre de req.user, nunca del param) para este caso.
  // (⚠️) Ruta exacta no confirmada contra el routes file — se infiere
  // '/users/me' seat el mismo prefijo que '/users/me/foto-perfil', que sí
  // está confirmado. Verificar contra userRoutes.js real.
  Future<void> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
  }) async {
    try {
      await _dio.put(
        '/users/me',
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

  // authController.js changePassword real no reemite cookies de sesión — solo
  // cambia la contraseña y pone primerInicioSesion:false en BD. El
  // access_token/refresh_token vigentes siguen siendo válidos tal cual.
  Future<void> changePassword({required String contrasenaActual, required String contrasenaNueva}) async {
    try {
      await _dio.post(
        '/auth/change-password',
        // authController.js changePassword real: destructura "contraseñaActual"/
        // "contraseñaNueva" (con ñ).
        data: {'contraseñaActual': contrasenaActual, 'contraseñaNueva': contrasenaNueva},
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// getUltimasSesiones real: para no-superadmin devuelve {ultimoAcceso},
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
