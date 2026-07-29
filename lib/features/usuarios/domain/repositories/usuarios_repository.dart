import '../../../../core/security/role.dart';
import '../../../auth/domain/entities/user.dart';

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

  Future<User> updateUsuario({
    required String id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? correo,
    String? telefono,
    UserRole? rol,
    String? institucionId,
  });

  /// DELETE /users/:id real: soft-delete a estado 'suspendido'.
  Future<void> suspenderUsuario(String id);

  /// No hay endpoint dedicado de reactivación — se hace vía PUT /users/:id
  /// {estado: 'activo'} (mismo mecanismo genérico que updateUsuario).
  Future<void> activarUsuario(String id);
}
