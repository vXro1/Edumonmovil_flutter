import '../../../../core/security/role.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/usuarios_repository.dart';
import '../datasources/usuarios_remote_datasource.dart';

class UsuariosRepositoryImpl implements UsuariosRepository {
  const UsuariosRepositoryImpl(this._remote);

  final UsuariosRemoteDataSource _remote;

  @override
  Future<UsuariosPage> fetchUsuarios({required int page, required int limit, UserRole? rol, String? estado}) async {
    final result = await _remote.fetchUsuarios(page: page, limit: limit, rol: rol, estado: estado);
    return UsuariosPage(items: result.items.map((e) => e.toEntity()).toList(), hasMore: result.hasMore);
  }

  @override
  Future<User> fetchUsuarioById(String id) async {
    final result = await _remote.fetchUsuarioById(id);
    return result.toEntity();
  }

  @override
  Future<User> createUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required UserRole rol,
    required String contrasena,
    String? correo,
    String? institucionId,
  }) async {
    final result = await _remote.createUsuario(
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      telefono: telefono,
      rol: rol,
      contrasena: contrasena,
      correo: correo,
      institucionId: institucionId,
    );
    return result.toEntity();
  }

  @override
  Future<User> updateUsuario({
    required String id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? correo,
    String? telefono,
  }) async {
    final result = await _remote.updateUsuario(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      correo: correo,
      telefono: telefono,
    );
    return result.toEntity();
  }

  @override
  Future<void> suspenderUsuario(String id) => _remote.suspenderUsuario(id);

  @override
  Future<void> activarUsuario(String id) => _remote.activarUsuario(id);
}
