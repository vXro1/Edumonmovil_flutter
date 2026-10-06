import '../../../../shared/models/archivo.dart';

enum EventoCategoria {
  escuelaPadres,
  tarea,
  institucional;

  static EventoCategoria fromApiString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'escuela_padres':
        return EventoCategoria.escuelaPadres;
      case 'tarea':
        return EventoCategoria.tarea;
      case 'institucional':
        return EventoCategoria.institucional;
      default:
        return EventoCategoria.institucional;
    }
  }

  String get apiValue => switch (this) {
    EventoCategoria.escuelaPadres => 'escuela_padres',
    EventoCategoria.tarea => 'tarea',
    EventoCategoria.institucional => 'institucional',
  };

  String get label => switch (this) {
    EventoCategoria.escuelaPadres => 'Escuela de padres',
    EventoCategoria.tarea => 'Tarea',
    EventoCategoria.institucional => 'Institucional',
  };
}

/// Entidad de dominio
class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    this.hora,
    this.ubicacion,
    this.categoria = EventoCategoria.institucional,
    this.cursosIds = const [],
    this.adjunto,
    this.estado = 'programado',
    this.cursosNombres = const [],
    this.docenteNombre,
    this.imagenPortadaUrl,
    this.fechaCreacion,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? hora;
  final String? ubicacion;
  final EventoCategoria categoria;
  final List<String> cursosIds;
  final Archivo? adjunto;

  final String estado;

  /// getEventoById popula cursosIds (nombre) y docenteId (nombre apellido).
  final List<String> cursosNombres;
  final String? docenteNombre;
  final String? imagenPortadaUrl;
  final DateTime? fechaCreacion;

  bool get cancelado => estado == 'cancelado';
  bool get finalizado => estado == 'finalizado';

  String get estadoLabel => switch (estado) {
    'en_curso' => 'En curso',
    'finalizado' => 'Finalizado',
    'cancelado' => 'Cancelado',
    _ => 'Programado',
  };
}
