import '../../domain/entities/perfil_activo.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación — BLUEPRINT.md FASE 5.5.
/// authController.js real guarda la sesión en cookies httpOnly (ver
/// RefreshInterceptor/CookieManager en ApiClient) — no hay token que guardar
/// a mano acá, el navegador/cliente HTTP la persiste solo.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<LoginResult> login({required String telefono, required String contrasena}) async {
    final response = await _remote.login(telefono: telefono, contrasena: contrasena);
    return LoginResult(
      user: response.user.toEntity(),
      primerInicioSesion: response.primerInicioSesion,
    );
  }

  @override
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile() async {
    final result = await _remote.fetchProfile();
    return (user: result.user.toEntity(), perfilActivo: result.perfilActivo?.toEntity());
  }

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<void> logoutAll() => _remote.logoutAll();

  @override
  Future<void> requestPasswordRecovery({required RecoveryMethod method, required String contact}) {
    return method == RecoveryMethod.correo
        ? _remote.forgotPasswordByEmail(contact)
        : _remote.forgotPasswordByPhone(contact);
  }

  @override
  Future<void> resetPassword({
    required RecoveryMethod method,
    required String contact,
    required String codigo,
    required String nuevaContrasena,
  }) {
    return method == RecoveryMethod.correo
        ? _remote.resetPasswordByEmail(correo: contact, codigo: codigo, contrasenaNueva: nuevaContrasena)
        : _remote.resetPasswordByPhone(telefono: contact, codigo: codigo, contrasenaNueva: nuevaContrasena);
  }
}
