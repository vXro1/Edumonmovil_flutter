import '../../../../shared/models/archivo.dart';

/// BLUEPRINT.md FASE 9.10: escuela_padres|tarea|institucional, con variantes
/// de institucional (reunion/actividad/otro) que EventosPage expone aparte.
enum EventoCategoria {
  escuelaPadres,
  institucional,
  reunion,
  actividad,
  otro;

  static EventoCategoria fromApiString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'escuela_padres':
        return EventoCategoria.escuelaPadres;
      case 'reunion':
        return EventoCategoria.reunion;
      case 'actividad':
        return EventoCategoria.actividad;
      case 'otro':
        return EventoCategoria.otro;
      case 'institucional':
        return EventoCategoria.institucional;
      default:
        return EventoCategoria.institucional;
    }
  }

  String get apiValue => switch (this) {
    EventoCategoria.escuelaPadres => 'escuela_padres',
    EventoCategoria.institucional => 'institucional',
    EventoCategoria.reunion => 'reunion',
    EventoCategoria.actividad => 'actividad',
    EventoCategoria.otro => 'otro',
  };

  String get label => switch (this) {
    EventoCategoria.escuelaPadres => 'Escuela de padres',
    EventoCategoria.institucional => 'Institucional',
    EventoCategoria.reunion => 'Reunión',
    EventoCategoria.actividad => 'Actividad',
    EventoCategoria.otro => 'Otro',
  };
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.10.
/// (⚠️) No vimos eventoController.js real — shapes inferidos del blueprint.
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
}
