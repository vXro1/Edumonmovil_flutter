import 'package:dio/dio.dart';

/// Excepción de red humanizada — BLUEPRINT.md FASE 10 (footnote de formato de error)
/// y FASE 11.6 (error_humanizer). El backend responde con 3 formatos distintos
/// de error: {message}, {error} o {errors:[...]} (validación) — se intentan los 3.
///
/// BUG CONFIRMADO (revisión funcional): los `errors[]` que devuelve
/// express-validator.array() en el backend real usan las claves `path`/`msg`
/// (o `param`/`msg` en versiones viejas) — nunca `field`/`message`. Antes acá
/// solo se buscaban `field`/`message`, así que ningún error de validación de
/// express-validator se parseaba nunca: el array quedaba vacío y siempre caía
/// al `message` genérico de nivel superior ("Errores de validación"), sin
/// mostrar nunca la causa específica por campo. Esto afectaba a TODOS los
/// formularios del backend (usuarios, cursos, instituciones, tareas, eventos...).
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
            // express-validator real: {type, value, msg, path, location} —
            // `path` (o `param` en versiones viejas), nunca `field`; `msg`,
            // nunca `message`. Se prueban todas las variantes por las dudas.
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
