/// Entidad de dominio — BLUEPRINT.md FASE 9.11.
/// Categorías reales de notificacionController.js/notificacionValidator.js
/// (`isIn(['tarea', 'entrega', 'calificacion', 'foro', 'evento', 'sistema'])`)
/// — el enum anterior (info/exito/warning/error/bienvenida) era un nivel de
/// severidad inventado que el backend real nunca envía, así que todas las
/// notificaciones caían siempre en el mismo ícono/color por defecto.
enum NotificacionTipo {
  tarea,
  entrega,
  calificacion,
  foro,
  evento,
  sistema;

  /// Un tipo desconocido no es crítico para la seguridad — cae a [sistema]
  /// en vez de lanzar, para no romper la lista entera de notificaciones por
  /// un valor nuevo no contemplado.
  static NotificacionTipo fromApiString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'tarea':
        return NotificacionTipo.tarea;
      case 'entrega':
        return NotificacionTipo.entrega;
      case 'calificacion':
        return NotificacionTipo.calificacion;
      case 'foro':
        return NotificacionTipo.foro;
      case 'evento':
        return NotificacionTipo.evento;
      default:
        return NotificacionTipo.sistema;
    }
  }
}

class Notificacion {
  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.createdAt,
  });

  final String id;
  final String titulo;
  final String mensaje;
  final NotificacionTipo tipo;
  final bool leida;
  final DateTime createdAt;
}
