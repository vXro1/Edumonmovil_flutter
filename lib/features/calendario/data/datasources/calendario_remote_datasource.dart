import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../eventos/domain/entities/evento.dart';
import '../../domain/entities/calendario_entry.dart';

/// Data source remoto — verificado contra calendarioController.js/
/// calendarioRoutes.js reales. Reemplaza la agregación 100% client-side que
/// hacía calendario_aggregator.dart (combinar TareasRepository.fetchTareas +
/// EventosRepository.fetchEventos a mano) por los endpoints dedicados, que ya
/// traen colores/estado resueltos en servidor y no tienen el límite fijo de
/// 200 tareas que tenía la agregación anterior.
class CalendarioRemoteDataSource {
  const CalendarioRemoteDataSource(this._dio);

  final Dio _dio;

  /// obtenerCalendarioUsuario real (GET /calendario/calendario): agrega
  /// tareas+eventos de TODOS los cursos accesibles al usuario (scoping por
  /// rol ya resuelto en backend).
  Future<List<CalendarioEntry>> fetchCalendarioUsuario() async {
    try {
      final response = await _dio.get('/calendario/calendario');
      return _parseItems(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// obtenerCalendarioCurso real (GET /calendario/:cursoId).
  Future<List<CalendarioEntry>> fetchCalendarioCurso(String cursoId) async {
    try {
      final response = await _dio.get('/calendario/$cursoId');
      return _parseItems(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  List<CalendarioEntry> _parseItems(dynamic data) {
    final rawList = data is Map ? data['items'] as List? : null;
    return (rawList ?? const []).map((e) => _entryFromJson(e as Map<String, dynamic>)).toList();
  }

  CalendarioEntry _entryFromJson(Map<String, dynamic> json) {
    final esTarea = json['tipo'] == 'tarea';
    final fecha = DateTime.tryParse((json['fecha'] ?? '').toString()) ?? DateTime.now();

    String? cursoId;
    String? cursoNombre;
    if (esTarea) {
      cursoId = json['cursoId']?.toString();
      cursoNombre = json['cursoNombre']?.toString();
    } else {
      // Un evento puede estar asociado a varios cursos (cursosIds/cursosNombres)
      // — CalendarioEntry solo modela uno, se toma el primero para el badge.
      final cursosIds = json['cursosIds'] as List?;
      final cursosNombres = json['cursosNombres'] as List?;
      cursoId = cursosIds != null && cursosIds.isNotEmpty ? cursosIds.first.toString() : null;
      cursoNombre = cursosNombres != null && cursosNombres.isNotEmpty ? cursosNombres.first.toString() : null;
    }

    // Tarea.estaVencida real (virtual) ya resuelve esto en el backend, pero
    // no viaja como booleano en el item de calendario — se recalcula acá con
    // el mismo criterio que Tarea.vencida en el resto de la app.
    final vencida = esTarea && json['estado'] == 'publicada' && fecha.isBefore(DateTime.now());

    return CalendarioEntry(
      id: (json['id'] ?? json['_id']).toString(),
      titulo: json['titulo']?.toString() ?? '',
      fecha: fecha,
      tipo: esTarea ? CalendarioEntryTipo.tarea : CalendarioEntryTipo.evento,
      categoria: esTarea ? null : EventoCategoria.fromApiString(json['categoria']?.toString()).label,
      cursoId: cursoId,
      cursoNombre: cursoNombre,
      vencida: vencida,
    );
  }
}
