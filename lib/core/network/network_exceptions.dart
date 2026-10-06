import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  factory AppException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AppException('La conexión tardó demasiado. Revisa tu internet e inténtalo de nuevo.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const AppException('No hay conexión a internet.');
    }

    final data = e.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (map['errors'] is List) {
        final fieldErrors = <String, String>{};
        for (final item in map['errors'] as List) {
          if (item is Map) {
            final field = item['field'] ?? item['path'] ?? item['param'];
            final msg = item['message'] ?? item['msg'];
            if (field != null && msg != null) {
              fieldErrors[field.toString()] = msg.toString();
            }
          }
        }
        if (fieldErrors.isNotEmpty) {
          return AppException(
            fieldErrors.values.first,
            statusCode: statusCode,
            fieldErrors: fieldErrors,
          );
        }
      }

      final message = map['message'] ?? map['error'];
      if (message is String && message.isNotEmpty) {
        return AppException(message, statusCode: statusCode);
      }
    }

    switch (statusCode) {
      case 401:
        return const AppException('Tu sesión expiró. Inicia sesión de nuevo.', statusCode: 401);
      case 403:
        return const AppException('No tienes permiso para realizar esta acción.', statusCode: 403);
      case 404:
        return const AppException('No se encontró el recurso solicitado.', statusCode: 404);
      case 500:
      case 502:
      case 503:
        return AppException('El servidor no está disponible. Inténtalo más tarde.', statusCode: statusCode);
      default:
        return AppException('Ocurrió un error inesperado. Inténtalo de nuevo.', statusCode: statusCode);
    }
  }

  @override
  String toString() => message;
}
