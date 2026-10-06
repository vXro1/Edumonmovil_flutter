import '../entities/perfil_activo.dart';
import '../entities/user.dart';

class LoginResult {
  const LoginResult({required this.user, required this.primerInicioSesion});

  final User user;
  final bool primerInicioSesion;
}

/// Interfaz de dominio
abstract class AuthRepository {
  Future<LoginResult> login({required String telefono, required String contrasena});

  /// getProfile trae junto al user el [PerfilActivo] de la sesión — ver
  /// PerfilActivo para por qué es la única fuente de verdad confiable de
  /// "qué perfil familiar está seleccionado ahora mismo".
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile();

  Future<void> logout();

  /// POST /auth/logout-all: cierra todas las sesiones/dispositivos del
  /// usuario, no solo la actual.
  Future<void> logoutAll();

  Future<void> requestPasswordRecovery({required String correo});

  Future<void> resetPassword({required String correo, required String codigo, required String nuevaContrasena});
}
