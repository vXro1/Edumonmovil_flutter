import '../../domain/entities/perfil.dart';
import '../../domain/repositories/perfiles_repository.dart';
import '../datasources/perfiles_remote_datasource.dart';

class PerfilesRepositoryImpl implements PerfilesRepository {
  const PerfilesRepositoryImpl(this._remote);

  final PerfilesRemoteDataSource _remote;

  @override
  Future<List<Perfil>> fetchPerfiles({String? activePerfilId}) async {
    final result = await _remote.fetchPerfiles();
    bool esActivo(String id) => activePerfilId != null && activePerfilId == id;
    return [
      result.titular.toEntity(esActivo: esActivo(result.titular.id)),
      for (final p in result.secundarios) p.toEntity(esActivo: esActivo(p.id)),
    ];
  }

  @override
  Future<Perfil> createPerfil({required String nombre, String? avatarUrl}) async {
    final result = await _remote.createPerfil(nombre: nombre, avatarUrl: avatarUrl);
    return result.toEntity(esActivo: false);
  }

  @override
  Future<Perfil> updatePerfil({required String id, String? nombre, String? avatarUrl}) async {
    final result = await _remote.updatePerfil(id: id, nombre: nombre, avatarUrl: avatarUrl);
    return result.toEntity(esActivo: false);
  }

  @override
  Future<void> deletePerfil(String id) => _remote.deletePerfil(id);

  @override
  Future<void> seleccionarPerfil(String perfilId) => _remote.seleccionarPerfil(perfilId);

  @override
  Future<void> updateFcmToken(String fcmToken, {String? perfilId}) =>
      _remote.updateFcmToken(fcmToken, perfilId: perfilId);
}
