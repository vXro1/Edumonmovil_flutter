enum CalendarioEntryTipo { tarea, evento }

/// Entrada unificada del calendario — combina Tareas (fechaEntrega) y
/// Eventos (fechaInicio) en un solo modelo para pintar el grid mensual.
///
/// (⚠️) El blueprint documenta `/calendario/:cursoId` como endpoint pero no
/// da el shape de su respuesta (no aparece ninguna entidad "Calendario" en
/// FASE 9) — en vez de adivinar un contrato sin ninguna pista, el calendario
/// se arma en cliente combinando TareasRepository.fetchTareas +
/// EventosRepository.fetchEventos, que sí están verificados/implementados.
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
