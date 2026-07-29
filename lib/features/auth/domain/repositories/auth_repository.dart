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

  Future<User> fetchProfile();

  Future<void> logout();

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
