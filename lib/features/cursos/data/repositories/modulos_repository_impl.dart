import '../../domain/entities/modulo.dart';
import '../../domain/repositories/modulos_repository.dart';
import '../datasources/modulos_remote_datasource.dart';

class ModulosRepositoryImpl implements ModulosRepository {
  const ModulosRepositoryImpl(this._remote);

  final ModulosRemoteDataSource _remote;

  @override
  Future<List<Modulo>> fetchModulos(String cursoId, {bool incluirInactivos = false}) async {
    final result = await _remote.fetchModulos(cursoId, incluirInactivos: incluirInactivos);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Modulo> createModulo({required String cursoId, required String titulo, String? descripcion}) async {
    final result = await _remote.createModulo(cursoId: cursoId, titulo: titulo, descripcion: descripcion);
    return result.toEntity();
  }

  @override
  Future<Modulo> updateModulo({required String id, required String titulo, String? descripcion}) async {
    final result = await _remote.updateModulo(id: id, titulo: titulo, descripcion: descripcion);
    return result.toEntity();
  }

  @override
  Future<void> deleteModulo(String id) => _remote.deleteModulo(id);

  @override
  Future<void> restoreModulo(String id) => _remote.restoreModulo(id);
}
