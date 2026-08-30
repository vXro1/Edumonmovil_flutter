import '../../../../core/security/role.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/padre_info.dart';

class UsuariosPage {
  const UsuariosPage({required this.items, required this.hasMore});

  final List<User> items;
  final bool hasMore;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.3.4 / FASE 10.2, verificada
/// contra userController.js real. (⚠️) getUsers real NO soporta búsqueda por
/// texto server-side (solo rol/estado) — el filtro de texto se hace en
/// cliente sobre lo ya paginado, por eso no hay parámetro `search` acá.
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

  /// userController.js real (updateUser): rol/estado/institucionId se borran
  /// de updateData antes de guardar — ese endpoint no puede cambiarlos, así
  /// que ni siquiera se aceptan acá para no sugerir que sí. Usá
  /// [activarUsuario]/[suspenderUsuario] para estado; rol/institución no
  /// tienen endpoint de reasignación en este backend.
  Future<User> updateUsuario({
    required String id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? correo,
    String? telefono,
  });

  /// DELETE /users/:id real: soft-delete a estado 'suspendido'.
  Future<void> suspenderUsuario(String id);

  /// PATCH /users/:id/reactivar real — endpoint dedicado (updateUser real
  /// borra "estado" del body, así que no se puede reactivar vía PUT genérico).
  Future<void> activarUsuario(String id);

  /// GET /users/padre/:padreId/info real — info detallada de un padre/
  /// acudiente (usado desde participantes_tab.dart para ver sus datos de
  /// contacto sin salir del curso).
  Future<PadreInfo> fetchPadreInfo(String padreId);
}
