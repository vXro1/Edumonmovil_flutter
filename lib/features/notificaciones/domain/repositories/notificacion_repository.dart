import '../entities/notificacion.dart';

class NotificacionesPage {
  const NotificacionesPage({required this.items, required this.hasMore});

  final List<Notificacion> items;
  final bool hasMore;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 10.8.
abstract class NotificacionRepository {
  /// POST /notificaciones real (solo administrador/superadmin) — envía una
  /// notificación puntual a un usuario.
  Future<void> createNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    NotificacionTipo tipo = NotificacionTipo.sistema,
  });

  Future<NotificacionesPage> fetchNotificaciones({required int page, required int limit, bool? leido});

  Future<int> fetchUnreadCount();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> delete(String id);

  /// DELETE /notificaciones/limpiar/antiguas real — borra las ya leídas con
  /// más de [dias] días; devuelve cuántas borró.
  Future<int> deleteLeidasAntiguas({int dias = 30});
}
