import '../../../../core/config/constants.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso — BLUEPRINT.md FASE 3.1.2.
/// Valida el formato antes de llamar al repositorio (teléfono 10 dígitos,
/// contraseña mínimo 6 caracteres); el prefijo +57 se antepone al enviar.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<LoginResult> call({required String telefono, required String contrasena}) {
    if (!AppConstants.phoneRegex.hasMatch(telefono)) {
      throw ArgumentError('El teléfono debe tener exactamente 10 dígitos.');
    }
    if (contrasena.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }
    return _repository.login(telefono: telefono, contrasena: contrasena);
  }
}
