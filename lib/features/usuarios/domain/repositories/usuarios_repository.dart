import '../../../../core/security/role.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/padre_info.dart';

class UsuariosPage {
  const UsuariosPage({required this.items, required this.hasMore});

  final List<User> items;
  final bool hasMore;
}

abstract class UsuariosRepository {
  Future<UsuariosPage> fetchUsuarios({required int page, required int limit, UserRole? rol, String? estado});

  Future<User> fetchUsuarioById(String id);

  Future<User> createUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required UserRole rol,
    required String contrasena,
    String? correo,
    String? institucionId,
  });

  Future<User> updateUsuario({
    required String id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? correo,
    String? telefono,
  });

  /// DELETE /users/:id: soft-delete a estado 'suspendido'.
  Future<void> suspenderUsuario(String id);

  /// PATCH /users/:id/reactivar — endpoint dedicado (updateUser
  /// borra "estado" del body, así que no se puede reactivar vía PUT genérico).
  Future<void> activarUsuario(String id);

  /// GET /users/padre/:padreId/info — info detallada de un padre/
  /// acudiente (usado desde participantes_tab.dart para ver sus datos de
  /// contacto sin salir del curso).
  Future<PadreInfo> fetchPadreInfo(String padreId);
}
