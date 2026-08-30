enum CalendarioEntryTipo { tarea, evento }

/// Entrada unificada del calendario — combina Tareas (fechaEntrega) y
/// Eventos (fechaInicio) en un solo modelo para pintar el grid mensual.
/// Poblada desde los endpoints reales de calendarioController.js (ver
/// CalendarioRemoteDataSource) — verificados contra el controller real.
class CalendarioEntry {
  const CalendarioEntry({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.tipo,
    this.categoria,
    this.cursoId,
    this.cursoNombre,
    this.vencida = false,
  });

  final String id;
  final String titulo;
  final DateTime fecha;
  final CalendarioEntryTipo tipo;
  final String? categoria;
  final String? cursoId;
  final String? cursoNombre;
  final bool vencida;
}
