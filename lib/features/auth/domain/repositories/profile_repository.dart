import '../entities/user_activity.dart';

/// Página de resultados paginados — usada por Sesiones activas (solo superadmin).
class PagedResult<T> {
  const PagedResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}

/// Resultado de GET /users/sesiones/ultimas — el backend real devuelve una
/// forma u otra según el rol del usuario autenticado, nunca ambas:
/// - No superadmin: solo [ultimoAcceso] (su propia última conexión).
/// - Superadmin: [usersActivity] paginado (actividad de todos los usuarios).
class SessionsInfo {
  const SessionsInfo({
    this.ultimoAcceso,
    this.usersActivity = const [],
    this.hasMore = false,
    required this.isAdminView,
  });

  final DateTime? ultimoAcceso;
  final List<UserActivity> usersActivity;
  final bool hasMore;

  /// true si la respuesta trajo la rama superadmin (lista de actividad de
  /// todos los usuarios); false si trajo solo [ultimoAcceso] propio.
  final bool isAdminView;
}

/// Interfaz de dominio para el Wizard de primer login y la pantalla de
/// último acceso/actividad — agrupados bajo la feature auth porque así los
/// ubica BLUEPRINT.md FASE 5.6.
/// Solo avatares predeterminados del sistema — sin subida de foto propia
/// (decisión de producto explícita, aunque el backend técnicamente la soporta).
abstract class ProfileRepository {
  Future<List<String>> fetchDefaultAvatars();

  Future<void> selectDefaultAvatar(String avatarUrl);

  /// updateOwnProfile real: el id sale siempre del token, nunca se manda.
  Future<void> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
  });

  Future<void> changePassword({required String contrasenaActual, required String contrasenaNueva});

  Future<SessionsInfo> fetchSessionsInfo({required int page, required int limit});

  /// PATCH /users/me/modo-oscuro real — sincroniza la preferencia de tema al
  /// backend (best-effort, no lanza si falla). "Sistema" no tiene equivalente
  /// booleano, así que solo se llama para Claro/Oscuro explícitos.
  Future<void> updateModoOscuro(bool modoOscuro);
}
