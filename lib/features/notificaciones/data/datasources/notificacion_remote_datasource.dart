import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/notificacion.dart';
import '../models/notificacion_model.dart';

/// Data source remoto — BLUEPRINT.md FASE 10.8.
class NotificacionRemoteDataSource {
  const NotificacionRemoteDataSource(this._dio);

  final Dio _dio;

  /// createNotificacion real (POST /notificaciones, admin/superadmin) —
  /// (⚠️) no vimos notificacionValidator.js/Notificacion.js reales, los
  /// nombres de campo se infieren del shape que ya devuelve getMisNotificaciones.
  Future<void> createNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    NotificacionTipo tipo = NotificacionTipo.sistema,
  }) async {
    try {
      await _dio.post(
        '/notificaciones',
        data: {'usuarioId': usuarioId, 'titulo': titulo, 'mensaje': mensaje, 'tipo': tipo.name},
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<({List<NotificacionModel> items, bool hasMore})> fetchNotificaciones({
    required int page,
    required int limit,
    bool? leido,
  }) async {
    try {
      final response = await _dio.get(
        '/notificaciones',
        queryParameters: {'page': page, 'limit': limit, 'leido': ?leido},
      );
      final data = response.data;
      final rawList = data is List
          ? data
          : (data is Map ? (data['notificaciones'] ?? data['data'] ?? data['items']) as List? : null);
      final items = (rawList ?? const [])
          .map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // getMisNotificaciones real devuelve pagination: {total, page, limit,
      // pages} — sin `hasNextPage`. Con esa key inexistente `hasMore` daba
      // siempre false y "Cargar más" nunca aparecía pasada la 1ra página.
      final pagination = data is Map ? data['pagination'] as Map<String, dynamic>? : null;
      final hasMore = pagination != null
          ? ((pagination['page'] as num?) ?? 1) < ((pagination['pages'] as num?) ?? 1)
          : items.length >= limit;
      return (items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get('/notificaciones/conteo-no-leidas');
      final data = response.data;
      if (data is num) return data.toInt();
      if (data is Map) {
        final value = data['conteo'] ?? data['count'] ?? data['total'] ?? data['noLeidas'];
        if (value is num) return value.toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notificaciones/$id/leer');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notificaciones/leer-todas');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/notificaciones/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// eliminarLeidasAntiguas real (DELETE /notificaciones/limpiar/antiguas)
  /// — borra las notificaciones ya leídas con más de [dias] días. Devuelve
  /// cuántas borró.
  Future<int> deleteLeidasAntiguas({int dias = 30}) async {
    try {
      final response = await _dio.delete('/notificaciones/limpiar/antiguas', queryParameters: {'dias': dias});
      final data = response.data;
      final eliminadas = data is Map ? data['eliminadas'] : null;
      return eliminadas is num ? eliminadas.toInt() : 0;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
