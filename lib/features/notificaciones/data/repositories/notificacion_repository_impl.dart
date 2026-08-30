import '../../domain/entities/notificacion.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../datasources/notificacion_remote_datasource.dart';

/// Implementación — BLUEPRINT.md FASE 5.5.
class NotificacionRepositoryImpl implements NotificacionRepository {
  const NotificacionRepositoryImpl(this._remote);

  final NotificacionRemoteDataSource _remote;

  @override
  Future<void> createNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    NotificacionTipo tipo = NotificacionTipo.sistema,
  }) {
    return _remote.createNotificacion(usuarioId: usuarioId, titulo: titulo, mensaje: mensaje, tipo: tipo);
  }

  @override
  Future<NotificacionesPage> fetchNotificaciones({required int page, required int limit, bool? leido}) async {
    final result = await _remote.fetchNotificaciones(page: page, limit: limit, leido: leido);
    return NotificacionesPage(items: result.items.map((e) => e.toEntity()).toList(), hasMore: result.hasMore);
  }

  @override
  Future<int> fetchUnreadCount() => _remote.fetchUnreadCount();

  @override
  Future<void> markAsRead(String id) => _remote.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _remote.markAllAsRead();

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<int> deleteLeidasAntiguas({int dias = 30}) => _remote.deleteLeidasAntiguas(dias: dias);
}
