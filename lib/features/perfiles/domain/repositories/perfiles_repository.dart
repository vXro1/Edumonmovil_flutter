import '../entities/perfil.dart';

/// Interfaz de dominio — BLUEPRINT.md FASE 3.7.1 / FASE 10.8.
/// (⚠️) No vimos perfilFamiliarController.js real — shapes inferidos del
/// blueprint. Máx 5 perfiles secundarios + titular (regla validada también
/// en cliente antes de llamar a createPerfil).
abstract class PerfilesRepository {
  Future<List<Perfil>> fetchPerfiles();

  Future<Perfil> createPerfil({required String nombre, String? avatarUrl});

  Future<Perfil> updatePerfil({required String id, String? nombre, String? avatarUrl});

  Future<void> deletePerfil(String id);

  /// perfilesSeleccionar real (⚠️) — la web documentaba que devuelve un JWT
  /// nuevo en el body, pero el backend ya migró login/refresh a cookies
  /// httpOnly (ver RefreshInterceptor); se asume que este endpoint sigue el
  /// mismo patrón y set-cookea el access_token nuevo solo, sin nada que leer
  /// del body — por eso no se parsea ningún token acá.
  Future<void> seleccionarPerfil(String perfilId);

  Future<void> updateFcmToken(String fcmToken);
}
