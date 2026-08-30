import '../../domain/entities/entrega.dart';
import '../../domain/repositories/entregas_repository.dart';
import '../datasources/entregas_remote_datasource.dart';

class EntregasRepositoryImpl implements EntregasRepository {
  const EntregasRepositoryImpl(this._remote);

  final EntregasRemoteDataSource _remote;

  @override
  Future<({List<Entrega> items, EntregasEstadisticas stats})> fetchEntregasPorTarea(String tareaId) async {
    final result = await _remote.fetchEntregasPorTarea(tareaId);
    return (
      items: result.items.map((e) => e.toEntity()).toList(),
      stats: EntregasEstadisticas(
        total: result.stats.total,
        enviadas: result.stats.enviadas,
        tarde: result.stats.tarde,
        valoradas: result.stats.valoradas,
      ),
    );
  }

  @override
  Future<Entrega?> fetchMiEntrega(String tareaId) async {
    final result = await _remote.fetchMiEntrega(tareaId);
    return result?.toEntity();
  }

  @override
  Future<Entrega> crearBorrador({
    required String tareaId,
    required String padreId,
    String? textoRespuesta,
    List<ArchivoUpload>? archivos,
  }) async {
    final result = await _remote.crearBorrador(
      tareaId: tareaId,
      padreId: padreId,
      textoRespuesta: textoRespuesta,
      archivos: archivos,
    );
    return result.toEntity();
  }

  @override
  Future<Entrega> actualizarBorrador({
    required String id,
    String? textoRespuesta,
    List<ArchivoUpload>? archivosNuevos,
  }) async {
    final result = await _remote.actualizarBorrador(id: id, textoRespuesta: textoRespuesta, archivosNuevos: archivosNuevos);
    return result.toEntity();
  }

  @override
  Future<void> enviarEntrega(String id) => _remote.enviarEntrega(id);

  @override
  Future<void> calificarEntrega({required String id, required int valoracion, String? comentario}) {
    return _remote.calificarEntrega(id: id, valoracion: valoracion, comentario: comentario);
  }

  @override
  Future<void> deleteEntrega(String id) => _remote.deleteEntrega(id);

  @override
  Future<Entrega> eliminarArchivoEntrega({required String id, required String archivoId}) async {
    final result = await _remote.eliminarArchivoEntrega(id: id, archivoId: archivoId);
    return result.toEntity();
  }
}
