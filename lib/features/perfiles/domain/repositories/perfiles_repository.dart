import '../entities/perfil.dart';

abstract class PerfilesRepository {
  /// [activePerfilId] es el id del perfil activo en la sesión actual (ver
  /// PerfilActivo, de GET /auth/profile) — se usa para marcar `esActivo` en
  /// el resultado, porque el propio GET /perfiles no trae ese dato (su
  /// `activo` es un flag de soft-delete, no de selección).
  Future<List<Perfil>> fetchPerfiles({String? activePerfilId});

  Future<Perfil> createPerfil({required String nombre, String? avatarUrl});

  Future<Perfil> updatePerfil({required String id, String? nombre, String? avatarUrl});

  Future<void> deletePerfil(String id);

  /// seleccionarPerfil reemplaza la cookie access_token con una que
  /// incluye el nuevo perfilId — no hay token que leer del body. El caller
  /// debe refrescar el estado de sesión después (ver AuthController.refreshUser)
  /// para que PerfilActivo refleje el cambio.
  Future<void> seleccionarPerfil(String perfilId);

  Future<void> updateFcmToken(String fcmToken, {String? perfilId});
}
