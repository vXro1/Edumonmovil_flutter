import '../../domain/entities/evento.dart';
import '../../domain/repositories/eventos_repository.dart';
import '../datasources/eventos_remote_datasource.dart';

class EventosRepositoryImpl implements EventosRepository {
  const EventosRepositoryImpl(this._remote);

  final EventosRemoteDataSource _remote;

  @override
  Future<List<Evento>> fetchEventos({String? cursoId}) async {
    final result = await _remote.fetchEventos(cursoId: cursoId);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Evento>> fetchEventosHoy() async {
    final result = await _remote.fetchEventosHoy();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Evento> fetchEventoById(String id) async {
    final result = await _remote.fetchEventoById(id);
    return result.toEntity();
  }

  @override
  Future<Evento> createEvento({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required String ubicacion,
    required EventoCategoria categoria,
    required List<String> cursosIds,
    ArchivoUpload? adjunto,
  }) async {
    final result = await _remote.createEvento(
      titulo: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      hora: hora,
      ubicacion: ubicacion,
      categoria: categoria,
      cursosIds: cursosIds,
      adjunto: adjunto,
    );
    return result.toEntity();
  }

  @override
  Future<Evento> updateEvento({
    required String id,
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? hora,
    String? ubicacion,
    EventoCategoria? categoria,
    List<String>? cursosIds,
    ArchivoUpload? adjunto,
  }) async {
    final result = await _remote.updateEvento(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      hora: hora,
      ubicacion: ubicacion,
      categoria: categoria,
      cursosIds: cursosIds,
      adjunto: adjunto,
    );
    return result.toEntity();
  }

  @override
  Future<void> deleteEvento(String id) => _remote.deleteEvento(id);

  @override
  Future<Evento> cancelarEvento(String id) async {
    final result = await _remote.cancelarEvento(id);
    return result.toEntity();
  }
}
