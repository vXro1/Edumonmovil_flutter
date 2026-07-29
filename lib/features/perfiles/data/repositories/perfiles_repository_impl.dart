import '../../domain/entities/perfil.dart';
import '../../domain/repositories/perfiles_repository.dart';
import '../datasources/perfiles_remote_datasource.dart';

class PerfilesRepositoryImpl implements PerfilesRepository {
  const PerfilesRepositoryImpl(this._remote);

  final PerfilesRemoteDataSource _remote;

  @override
  Future<List<Perfil>> fetchPerfiles() async {
    final result = await _remote.fetchPerfiles();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Perfil> createPerfil({required String nombre, String? avatarUrl}) async {
    final result = await _remote.createPerfil(nombre: nombre, avatarUrl: avatarUrl);
    return result.toEntity();
  }

  @override
  Future<Perfil> updatePerfil({required String id, String? nombre, String? avatarUrl}) async {
    final result = await _remote.updatePerfil(id: id, nombre: nombre, avatarUrl: avatarUrl);
    return result.toEntity();
  }

  @override
  Future<void> deletePerfil(String id) => _remote.deletePerfil(id);

  @override
  Future<void> seleccionarPerfil(String perfilId) => _remote.seleccionarPerfil(perfilId);

  @override
  Future<void> updateFcmToken(String fcmToken) => _remote.updateFcmToken(fcmToken);
}
