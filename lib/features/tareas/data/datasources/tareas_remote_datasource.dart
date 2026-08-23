import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/tarea.dart';
import '../../domain/repositories/tareas_repository.dart';
import '../models/tarea_model.dart';

List<Map<String, dynamic>> _enlacesJson(List<EnlaceInput>? enlaces) => [for (final e in enlaces ?? const []) e.toJson()];

/// Data source remoto — BLUEPRINT.md FASE 10.5.
/// (⚠️) No vimos tareaController.js real — shapes inferidos del blueprint.
class TareasRemoteDataSource {
  const TareasRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({List<TareaModel> items, bool hasMore})> fetchTareas({
    String? cursoId,
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _dio.get(
        '/tareas',
        queryParameters: {'page': page, 'limit': limit, 'cursoId': ?cursoId},
      );
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['tareas'] ?? data['data']) as List? : null);
      final items = (rawList ?? const []).map((e) => TareaModel.fromJson(e as Map<String, dynamic>)).toList();
      final pagination = data is Map ? data['pagination'] as Map<String, dynamic>? : null;
      final hasMore = pagination != null ? pagination['hasNextPage'] == true : items.length >= limit;
      return (items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<TareaModel> fetchTareaById(String id) async {
    try {
      final response = await _dio.get('/tareas/$id');
      final data = response.data;
      final json = data is Map ? (data['tarea'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return TareaModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// tareaController.js real (pull 85fa452/e3e8d5a): el `docenteId` del body
  /// se ignora siempre — el backend usa el userId del token. Ya no se manda.
  /// [moduloId] es obligatorio: Tarea.js lo marca `required` y
  /// createTareaValidator devuelve 400 "El ID del módulo es obligatorio" sin él.
  Future<TareaModel> createTarea({
    required String titulo,
    String? descripcion,
    required String cursoId,
    required String moduloId,
    DateTime? fechaEntrega,
    required AsignacionTipo asignacionTipo,
    required TipoEntrega tipoEntrega,
    List<String>? participantesSeleccionados,
    List<String>? etiquetas,
    String? criterios,
    List<ArchivoUpload>? archivos,
    List<EnlaceInput>? enlaces,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': titulo,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'cursoId': cursoId,
        'moduloId': moduloId,
        if (fechaEntrega != null) 'fechaEntrega': fechaEntrega.toIso8601String(),
        'asignacionTipo': asignacionTipo == AsignacionTipo.seleccionados ? 'seleccionados' : 'todos',
        'tipoEntrega': tipoEntrega.apiValue,
        if (participantesSeleccionados != null) 'participantesSeleccionados': jsonEncode(participantesSeleccionados),
        if (etiquetas != null) 'etiquetas': jsonEncode(etiquetas),
        if (criterios != null && criterios.isNotEmpty) 'criterios': criterios,
        if (enlaces != null && enlaces.isNotEmpty) 'enlaces': jsonEncode(_enlacesJson(enlaces)),
        if (archivos != null)
          'archivos': [for (final a in archivos) MultipartFile.fromBytes(a.bytes, filename: a.filename)],
      });
      final response = await _dio.post('/tareas', data: formData);
      final data = response.data;
      final json = data is Map ? (data['tarea'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return TareaModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<TareaModel> updateTarea({
    required String id,
    String? titulo,
    String? descripcion,
    String? moduloId,
    DateTime? fechaEntrega,
    AsignacionTipo? asignacionTipo,
    TipoEntrega? tipoEntrega,
    List<String>? participantesSeleccionados,
    List<String>? etiquetas,
    String? criterios,
    List<ArchivoUpload>? archivosNuevos,
    List<EnlaceInput>? enlacesNuevos,
    List<String>? archivosAEliminar,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': ?titulo,
        'descripcion': ?descripcion,
        'moduloId': ?moduloId,
        if (fechaEntrega != null) 'fechaEntrega': fechaEntrega.toIso8601String(),
        if (asignacionTipo != null)
          'asignacionTipo': asignacionTipo == AsignacionTipo.seleccionados ? 'seleccionados' : 'todos',
        if (tipoEntrega != null) 'tipoEntrega': tipoEntrega.apiValue,
        if (participantesSeleccionados != null) 'participantesSeleccionados': jsonEncode(participantesSeleccionados),
        if (etiquetas != null) 'etiquetas': jsonEncode(etiquetas),
        'criterios': ?criterios,
        // updateTarea real lee los enlaces nuevos de "nuevosEnlaces" (o
        // "enlaces" si ese no viene) — se manda "nuevosEnlaces" explícito
        // para no chocar con el nombre que usa createTarea.
        if (enlacesNuevos != null && enlacesNuevos.isNotEmpty) 'nuevosEnlaces': jsonEncode(_enlacesJson(enlacesNuevos)),
        if (archivosAEliminar != null && archivosAEliminar.isNotEmpty) 'archivosAEliminar': jsonEncode(archivosAEliminar),
        if (archivosNuevos != null)
          'archivos': [for (final a in archivosNuevos) MultipartFile.fromBytes(a.bytes, filename: a.filename)],
      });
      final response = await _dio.put('/tareas/$id', data: formData);
      final data = response.data;
      final json = data is Map ? (data['tarea'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return TareaModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> cerrarTarea(String id) async {
    try {
      await _dio.patch('/tareas/$id/cerrar');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteTarea(String id) async {
    try {
      await _dio.delete('/tareas/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
