import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/foros_repository.dart';
import '../models/foro_model.dart';

/// Data source remoto — BLUEPRINT.md FASE 10.6.
/// (⚠️) No vimos foroController.js/mensajeForoController.js reales — shapes
/// inferidos del blueprint.
class ForosRemoteDataSource {
  const ForosRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ForoModel>> fetchForosPorCurso(String cursoId) async {
    try {
      final response = await _dio.get('/foros/curso/$cursoId');
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['foros'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => ForoModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ForoModel> fetchForoById(String id) async {
    try {
      final response = await _dio.get('/foros/$id');
      final data = response.data;
      final json = data is Map ? (data['foro'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return ForoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ForoModel> createForo({
    required String titulo,
    String? descripcion,
    required String cursoId,
    bool publico = false,
    List<ArchivoUpload>? archivos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': titulo,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'cursoId': cursoId,
        'publico': publico.toString(),
        if (archivos != null)
          'archivos': [for (final a in archivos) MultipartFile.fromBytes(a.bytes, filename: a.filename)],
      });
      final response = await _dio.post('/foros', data: formData);
      final data = response.data;
      final json = data is Map ? (data['foro'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return ForoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> toggleEstadoForo({required String id, required bool cerrado}) async {
    try {
      await _dio.patch('/foros/$id/estado', data: {'estado': cerrado ? 'cerrado' : 'activo'});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteForo(String id) async {
    try {
      await _dio.delete('/foros/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<MensajeForoModel>> fetchMensajes(String foroId) async {
    try {
      final response = await _dio.get('/mensajes-foro/foro/$foroId');
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['mensajes'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => MensajeForoModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<MensajeForoModel> enviarMensaje({
    required String foroId,
    required String contenido,
    String? respuestaA,
    List<ArchivoUpload>? archivos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'foroId': foroId,
        'contenido': contenido,
        'respuestaA': ?respuestaA,
        if (archivos != null)
          'archivos': [for (final a in archivos) MultipartFile.fromBytes(a.bytes, filename: a.filename)],
      });
      final response = await _dio.post('/mensajes-foro', data: formData);
      final data = response.data;
      final json = data is Map ? (data['mensaje'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return MensajeForoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> toggleLike(String mensajeId) async {
    try {
      await _dio.post('/mensajes-foro/$mensajeId/like');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> editarMensaje({required String id, required String contenido}) async {
    try {
      await _dio.put('/mensajes-foro/$id', data: {'contenido': contenido});
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteMensaje(String id) async {
    try {
      await _dio.delete('/mensajes-foro/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
