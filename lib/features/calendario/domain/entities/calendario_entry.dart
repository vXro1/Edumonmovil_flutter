enum CalendarioEntryTipo { tarea, evento }

class CalendarioEntry {
  const CalendarioEntry({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.tipo,
    this.categoria,
    this.cursoId,
    this.cursoNombre,
    this.cursosNombres = const [],
    this.vencida = false,
    this.descripcion,
    this.fechaFin,
    this.hora,
    this.ubicacion,
    this.estado,
  });

  final String id;
  final String titulo;
  final DateTime fecha;
  final CalendarioEntryTipo tipo;

  /// Etiqueta legible de la categoría (solo eventos).
  final String? categoria;
  final String? cursoId;
  final String? cursoNombre;

  /// Un evento puede pertenecer a varios cursos — todos sus nombres.
  final List<String> cursosNombres;
  final bool vencida;

  final String? descripcion;
  final DateTime? fechaFin;
  final String? hora;
  final String? ubicacion;
  final String? estado;
}
