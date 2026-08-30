import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/foros_repository.dart';
import '../models/foro_dashboard_model.dart';
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

  /// getDashboardForo real (GET /foros/:id/dashboard) — accesible a
  /// cualquier usuario con acceso al foro (foro.tieneAcceso), no solo
  /// docente/administrador.
  Future<ForoDashboardModel> fetchDashboard(String foroId) async {
    try {
      final response = await _dio.get('/foros/$foroId/dashboard');
      return ForoDashboardModel.fromJson(response.data as Map<String, dynamic>);
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

  // crearForoValidator real: descripcion es obligatoria (10-2000 caracteres),
  // no opcional — create_foro_sheet.dart ya la validaba así en la UI, esto
  // solo alinea la firma para que no quede como opcional "por las dudas".
  Future<ForoModel> createForo({
    required String titulo,
    required String descripcion,
    required String cursoId,
    bool publico = false,
    List<ArchivoUpload>? archivos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'titulo': titulo,
        'descripcion': descripcion,
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

  /// actualizarForo real (PUT /foros/:id) — solo título/descripción/público;
  /// el estado (abrir/cerrar) tiene su propio endpoint (toggleEstadoForo) y
  /// no soporta reemplazar archivos adjuntos.
  Future<ForoModel> updateForo({required String id, String? titulo, String? descripcion, bool? publico}) async {
    try {
      final response = await _dio.put(
        '/foros/$id',
        data: {'titulo': ?titulo, 'descripcion': ?descripcion, 'publico': ?publico},
      );
      final data = response.data;
      final json = data is Map ? (data['foro'] ?? data) as Map<String, dynamic> : <String, dynamic>{};
      return ForoModel.fromJson(json);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // BUG REAL corregido: Foro.js real solo acepta estado "abierto"/"cerrado"
  // — "activo" no existe en el enum, así que reabrir un foro (cerrado→false)
  // siempre devolvía 400 "Estado inválido".
  Future<void> toggleEstadoForo({required String id, required bool cerrado}) async {
    try {
      await _dio.patch('/foros/$id/estado', data: {'estado': cerrado ? 'cerrado' : 'abierto'});
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
