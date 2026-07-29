import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../auth/data/models/user_model.dart';

/// Data source remoto — shapes verificados contra userController.js real:
/// getUsers → {users:[...], pagination}; getUserById → doc crudo;
/// createUser/updateUser/deleteUser → {message, user: doc}.
class UsuariosRemoteDataSource {
  const UsuariosRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({List<UserModel> items, bool hasMore})> fetchUsuarios({
    required int page,
    required int limit,
    UserRole? rol,
    String? estado,
  }) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (rol != null) 'rol': rol.toApiString,
          'estado': ?estado,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['users'] as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      final pagination = data['pagination'] as Map<String, dynamic>?;
      return (items: items, hasMore: pagination?['hasNextPage'] == true);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserModel> fetchUsuarioById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserModel> createUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required UserRole rol,
    required String contrasena,
    String? correo,
    String? institucionId,
  }) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'cedula': cedula,
          'telefono': telefono,
          'rol': rol.toApiString,
          'contraseña': contrasena,
          if (correo != null && correo.isNotEmpty) 'correo': correo,
          'institucionId': ?institucionId,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserModel> updateUsuario({
    required String id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? correo,
    String? telefono,
    UserRole? rol,
    String? institucionId,
    String? estado,
  }) async {
    try {
      final response = await _dio.put(
        '/users/$id',
        data: {
          'nombre': ?nombre,
          'apellido': ?apellido,
          'cedula': ?cedula,
          'correo': ?correo,
          'telefono': ?telefono,
          if (rol != null) 'rol': rol.toApiString,
          'institucionId': ?institucionId,
          'estado': ?estado,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> suspenderUsuario(String id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> activarUsuario(String id) async {
    try {
      await _dio.put('/users/$id', data: {'estado': 'activo'});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
