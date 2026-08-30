import '../entities/perfil_activo.dart';
import '../entities/user.dart';

class LoginResult {
  const LoginResult({required this.user, required this.primerInicioSesion});

  final User user;
  final bool primerInicioSesion;
}

/// Método de contacto para recuperación de contraseña — BLUEPRINT.md FASE 3.1.3.
enum RecoveryMethod { correo, telefono }

/// Interfaz de dominio — BLUEPRINT.md FASE 5.5 / FASE 10.1.
abstract class AuthRepository {
  Future<LoginResult> login({required String telefono, required String contrasena});

  /// getProfile real trae junto al user el [PerfilActivo] de la sesión — ver
  /// PerfilActivo para por qué es la única fuente de verdad confiable de
  /// "qué perfil familiar está seleccionado ahora mismo".
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile();

  Future<void> logout();

  /// POST /auth/logout-all real: cierra todas las sesiones/dispositivos del
  /// usuario, no solo la actual.
  Future<void> logoutAll();

  /// [contact] es el correo o el teléfono, según [method].
  Future<void> requestPasswordRecovery({required RecoveryMethod method, required String contact});

  /// [contact] es el correo o el teléfono, según [method].
  Future<void> resetPassword({
    required RecoveryMethod method,
    required String contact,
    required String codigo,
    required String nuevaContrasena,
  });
}
