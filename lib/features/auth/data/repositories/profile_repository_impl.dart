import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implementación — BLUEPRINT.md FASE 5.5.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<List<String>> fetchDefaultAvatars() => _remote.fetchDefaultAvatars();

  @override
  Future<void> selectDefaultAvatar(String avatarUrl) => _remote.selectDefaultAvatar(avatarUrl);

  @override
  Future<void> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
  }) {
    return _remote.updateProfile(nombre: nombre, apellido: apellido, correo: correo, telefono: telefono);
  }

  @override
  Future<void> changePassword({required String contrasenaActual, required String contrasenaNueva}) {
    return _remote.changePassword(contrasenaActual: contrasenaActual, contrasenaNueva: contrasenaNueva);
  }

  @override
  Future<SessionsInfo> fetchSessionsInfo({required int page, required int limit}) async {
    final result = await _remote.fetchSessionsInfo(page: page, limit: limit);
    return SessionsInfo(
      ultimoAcceso: result.ultimoAcceso,
      usersActivity: result.usersActivity.map((e) => e.toEntity()).toList(),
      hasMore: result.hasMore,
      isAdminView: result.isAdminView,
    );
  }
}
