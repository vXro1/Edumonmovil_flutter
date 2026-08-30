import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/evento.dart';
import '../../domain/repositories/eventos_repository.dart';
import '../models/evento_model.dart';

/// Data source remoto — BLUEPRINT.md FASE 10.7.
/// (⚠️) No vimos eventoController.js real — shapes inferidos del blueprint.
class EventosRemoteDataSource {
  const EventosRemoteDataSource(this._dio);

  final Dio _dio;

  // getEventos real pagina con límite por defecto 10 (máx 50) y devuelve
  // {eventos, pagination} — sin `limit` explícito, listas con más de 10
  // eventos quedaban truncadas en silencio sin avisar que había más páginas.
  // Se pide el máximo permitido; una lista con más de 50 eventos igual
  // necesitaría "cargar más" real (no implementado en EventosScreen).
  Future<List<EventoModel>> fetchEventos({String? cursoId}) async {
    try {
      final response = await _dio.get('/eventos', queryParameters: {'cursoId': ?cursoId, 'limit': 50});
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['eventos'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => EventoModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventoModel>> fetchEventosHoy() async {
    try {
      final response = await _dio.get('/eventos/hoy');
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['eventos'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => EventoModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<EventoModel> fetchEventoById(String id) async {
    try {
      final response = await _dio.get('/eventos/$id');
      final data = response.data;
      final json = data is Map ? (data['evento'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return EventoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // eventoValidator.js real: descripcion (min 10), fechaFin (posterior a
  // fechaInicio), hora y ubicacion son TODOS obligatorios al crear — antes
  // acá eran opcionales y el formulario los etiquetaba "(opcional)", así que
  // omitirlos siempre devolvía 400. cursosIds también debe ser un array NO
  // vacío (sin default acá: el caller debe validar la selección mínima).
  Future<EventoModel> createEvento({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required String ubicacion,
    required EventoCategoria categoria,
    required List<String> cursosIds,
    ArchivoUpload? adjunto,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': titulo,
        'descripcion': descripcion,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'hora': hora,
        'ubicacion': ubicacion,
        'categoria': categoria.apiValue,
        'cursosIds': jsonEncode(cursosIds),
        if (adjunto != null) 'adjunto': MultipartFile.fromBytes(adjunto.bytes, filename: adjunto.filename),
      });
      final response = await _dio.post('/eventos', data: formData);
      final data = response.data;
      final json = data is Map ? (data['evento'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return EventoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<EventoModel> updateEvento({
    required String id,
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? hora,
    String? ubicacion,
    EventoCategoria? categoria,
    List<String>? cursosIds,
    ArchivoUpload? adjunto,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': ?titulo,
        'descripcion': ?descripcion,
        if (fechaInicio != null) 'fechaInicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'fechaFin': fechaFin.toIso8601String(),
        'hora': ?hora,
        'ubicacion': ?ubicacion,
        if (categoria != null) 'categoria': categoria.apiValue,
        if (cursosIds != null) 'cursosIds': jsonEncode(cursosIds),
        if (adjunto != null) 'adjunto': MultipartFile.fromBytes(adjunto.bytes, filename: adjunto.filename),
      });
      final response = await _dio.put('/eventos/$id', data: formData);
      final data = response.data;
      final json = data is Map ? (data['evento'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return EventoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteEvento(String id) async {
    try {
      await _dio.delete('/eventos/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// cancelarEvento real (eventoRoutes.js: PATCH /eventos/:id/cancelar):
  /// soft-cancel — pone estado:'cancelado' sin borrar el evento (a
  /// diferencia de deleteEvento, que sí lo elimina y limpia sus adjuntos de
  /// Cloudinary). 400 si ya está cancelado o si ya finalizó.
  Future<EventoModel> cancelarEvento(String id) async {
    try {
      final response = await _dio.patch('/eventos/$id/cancelar');
      final data = response.data;
      final json = data is Map ? (data['evento'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return EventoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
