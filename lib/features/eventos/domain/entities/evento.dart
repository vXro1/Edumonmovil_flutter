import '../../../../shared/models/archivo.dart';

/// Evento.js real: enum estricto de solo 3 valores — `reunion`/`actividad`/
/// `otro` NO existen en el backend (BUG CONFIRMADO: el dropdown los ofrecía
/// igual, así que elegirlos siempre devolvía 400 "La categoría debe ser:
/// escuela_padres, tarea o institucional").
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

/// Entidad de dominio — verificada contra eventoController.js/Evento.js reales.
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

  /// Evento.js real: enum ["programado", "en_curso", "finalizado",
  /// "cancelado"] — el pre('save') lo recalcula por fecha en cada save(),
  /// salvo "cancelado" (cancelarEvento usa findByIdAndUpdate a propósito
  /// para no pisarlo).
  final String estado;

  bool get cancelado => estado == 'cancelado';
  bool get finalizado => estado == 'finalizado';
}
