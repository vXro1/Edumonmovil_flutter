import '../../domain/entities/tarea.dart';
import '../../domain/repositories/tareas_repository.dart';
import '../datasources/tareas_remote_datasource.dart';

class TareasRepositoryImpl implements TareasRepository {
  const TareasRepositoryImpl(this._remote);

  final TareasRemoteDataSource _remote;

  @override
  Future<TareasPage> fetchTareas({String? cursoId, required int page, required int limit}) async {
    final result = await _remote.fetchTareas(cursoId: cursoId, page: page, limit: limit);
    return TareasPage(items: result.items.map((e) => e.toEntity()).toList(), hasMore: result.hasMore);
  }

  @override
  Future<Tarea> fetchTareaById(String id) async {
    final result = await _remote.fetchTareaById(id);
    return result.toEntity();
  }

  @override
  Future<Tarea> createTarea({
    required String titulo,
    String? descripcion,
    required String cursoId,
    String? moduloId,
    DateTime? fechaEntrega,
    required AsignacionTipo asignacionTipo,
    required TipoEntrega tipoEntrega,
    List<String>? participantesSeleccionados,
    List<ArchivoUpload>? archivos,
  }) async {
    final result = await _remote.createTarea(
      titulo: titulo,
      descripcion: descripcion,
      cursoId: cursoId,
      moduloId: moduloId,
      fechaEntrega: fechaEntrega,
      asignacionTipo: asignacionTipo,
      tipoEntrega: tipoEntrega,
      participantesSeleccionados: participantesSeleccionados,
      archivos: archivos,
    );
    return result.toEntity();
  }

  @override
  Future<Tarea> updateTarea({
    required String id,
    String? titulo,
    String? descripcion,
    DateTime? fechaEntrega,
    AsignacionTipo? asignacionTipo,
    TipoEntrega? tipoEntrega,
    List<String>? participantesSeleccionados,
    List<ArchivoUpload>? archivosNuevos,
  }) async {
    final result = await _remote.updateTarea(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      fechaEntrega: fechaEntrega,
      asignacionTipo: asignacionTipo,
      tipoEntrega: tipoEntrega,
      participantesSeleccionados: participantesSeleccionados,
      archivosNuevos: archivosNuevos,
    );
    return result.toEntity();
  }

  @override
  Future<void> cerrarTarea(String id) => _remote.cerrarTarea(id);

  @override
  Future<void> deleteTarea(String id) => _remote.deleteTarea(id);
}
