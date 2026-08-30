import '../../domain/entities/foro.dart';
import '../../domain/entities/foro_dashboard.dart';
import '../../domain/repositories/foros_repository.dart';
import '../datasources/foros_remote_datasource.dart';

class ForosRepositoryImpl implements ForosRepository {
  const ForosRepositoryImpl(this._remote);

  final ForosRemoteDataSource _remote;

  @override
  Future<List<Foro>> fetchForosPorCurso(String cursoId) async {
    final result = await _remote.fetchForosPorCurso(cursoId);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Foro> fetchForoById(String id) async {
    final result = await _remote.fetchForoById(id);
    return result.toEntity();
  }

  @override
  Future<ForoDashboard> fetchDashboard(String foroId) async {
    final result = await _remote.fetchDashboard(foroId);
    return result.toEntity();
  }

  @override
  Future<Foro> createForo({
    required String titulo,
    required String descripcion,
    required String cursoId,
    bool publico = false,
    List<ArchivoUpload>? archivos,
  }) async {
    final result = await _remote.createForo(
      titulo: titulo,
      descripcion: descripcion,
      cursoId: cursoId,
      publico: publico,
      archivos: archivos,
    );
    return result.toEntity();
  }

  @override
  Future<Foro> updateForo({required String id, String? titulo, String? descripcion, bool? publico}) async {
    final result = await _remote.updateForo(id: id, titulo: titulo, descripcion: descripcion, publico: publico);
    return result.toEntity();
  }

  @override
  Future<void> toggleEstadoForo({required String id, required bool cerrado}) {
    return _remote.toggleEstadoForo(id: id, cerrado: cerrado);
  }

  @override
  Future<void> deleteForo(String id) => _remote.deleteForo(id);

  @override
  Future<List<MensajeForo>> fetchMensajes(String foroId) async {
    final result = await _remote.fetchMensajes(foroId);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<MensajeForo> enviarMensaje({
    required String foroId,
    required String contenido,
    String? respuestaA,
    List<ArchivoUpload>? archivos,
  }) async {
    final result = await _remote.enviarMensaje(
      foroId: foroId,
      contenido: contenido,
      respuestaA: respuestaA,
      archivos: archivos,
    );
    return result.toEntity();
  }

  @override
  Future<void> toggleLike(String mensajeId) => _remote.toggleLike(mensajeId);

  @override
  Future<void> editarMensaje({required String id, required String contenido}) {
    return _remote.editarMensaje(id: id, contenido: contenido);
  }

  @override
  Future<void> deleteMensaje(String id) => _remote.deleteMensaje(id);
}
