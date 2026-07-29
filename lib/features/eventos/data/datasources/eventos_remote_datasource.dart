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

  Future<List<EventoModel>> fetchEventos({String? cursoId}) async {
    try {
      final response = await _dio.get('/eventos', queryParameters: {'cursoId': ?cursoId});
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

  Future<EventoModel> createEvento({
    required String titulo,
    String? descripcion,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? hora,
    String? ubicacion,
    required EventoCategoria categoria,
    List<String> cursosIds = const [],
    ArchivoUpload? adjunto,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': titulo,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'fechaInicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'fechaFin': fechaFin.toIso8601String(),
        if (hora != null && hora.isNotEmpty) 'hora': hora,
        if (ubicacion != null && ubicacion.isNotEmpty) 'ubicacion': ubicacion,
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
}
