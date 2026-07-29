import '../entities/notificacion.dart';

class NotificacionesPage {
  const NotificacionesPage({required this.items, required this.hasMore});

  final List<Notificacion> items;
  final bool hasMore;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 10.8.
abstract class NotificacionRepository {
  Future<NotificacionesPage> fetchNotificaciones({required int page, required int limit, bool? leido});

  Future<int> fetchUnreadCount();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> delete(String id);
}
