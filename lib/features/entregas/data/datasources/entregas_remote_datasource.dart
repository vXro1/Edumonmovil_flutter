import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/entregas_repository.dart';
import '../models/entrega_model.dart';

typedef EntregasStats = ({int total, int enviadas, int tarde, int valoradas});

/// Data source remoto — shapes verificados contra entregaController.js real.
class EntregasRemoteDataSource {
  const EntregasRemoteDataSource(this._dio);

  final Dio _dio;

  /// getEntregasByTarea real: excluye borradores (solo enviada/tarde) y
  /// devuelve {tarea, entregas, estadisticas: {total,enviadas,tarde,valoradas},
  /// pagination} — se usan las estadisticas del backend en vez de calcularlas
  /// en cliente, porque con paginación el conteo client-side subestimaría el total.
  Future<({List<EntregaModel> items, EntregasStats stats})> fetchEntregasPorTarea(String tareaId) async {
    try {
      final response = await _dio.get('/entregas/tarea/$tareaId');
      final data = response.data as Map<String, dynamic>;
      final items = (data['entregas'] as List).map((e) => EntregaModel.fromJson(e as Map<String, dynamic>)).toList();
      final stats = data['estadisticas'] as Map<String, dynamic>? ?? const {};
      int asInt(dynamic v) => v is num ? v.toInt() : 0;
      return (
        items: items,
        stats: (
          total: asInt(stats['total']),
          enviadas: asInt(stats['enviadas']),
          tarde: asInt(stats['tarde']),
          valoradas: asInt(stats['valoradas']),
        ),
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// getEntregasByPadreAndTarea real (detrás de /entregas/mis-entregas/:tareaId)
  /// devuelve {entregas: [...], total} — una LISTA, no un objeto suelto —
  /// aunque en la práctica solo puede haber 0 o 1 porque createEntrega
  /// rechaza duplicados por (tareaId, padreId).
  Future<EntregaModel?> fetchMiEntrega(String tareaId) async {
    try {
      final response = await _dio.get('/entregas/mis-entregas/$tareaId');
      final data = response.data as Map<String, dynamic>;
      final items = data['entregas'] as List? ?? const [];
      if (items.isEmpty) return null;
      return EntregaModel.fromJson(items.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<EntregaModel> crearBorrador({
    required String tareaId,
    required String padreId,
    String? textoRespuesta,
    List<ArchivoUpload>? archivos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'tareaId': tareaId,
        'padreId': padreId,
        if (textoRespuesta != null && textoRespuesta.isNotEmpty) 'textoRespuesta': textoRespuesta,
        'estado': 'borrador',
        if (archivos != null)
          'archivos': [for (final a in archivos) MultipartFile.fromBytes(a.bytes, filename: a.filename)],
      });
      final response = await _dio.post('/entregas', data: formData);
      final data = response.data as Map<String, dynamic>;
      return EntregaModel.fromJson(data['entrega'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<EntregaModel> actualizarBorrador({
    required String id,
    String? textoRespuesta,
    List<ArchivoUpload>? archivosNuevos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'textoRespuesta': ?textoRespuesta,
        if (archivosNuevos != null)
          'archivos': [for (final a in archivosNuevos) MultipartFile.fromBytes(a.bytes, filename: a.filename)],
      });
      final response = await _dio.put('/entregas/$id', data: formData);
      final data = response.data as Map<String, dynamic>;
      return EntregaModel.fromJson(data['entrega'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> enviarEntrega(String id) async {
    try {
      await _dio.patch('/entregas/$id/enviar');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> calificarEntrega({required String id, required int valoracion, String? comentario}) async {
    try {
      await _dio.patch(
        '/entregas/$id/calificar',
        data: {'valoracion': valoracion, if (comentario != null && comentario.isNotEmpty) 'comentario': comentario},
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteEntrega(String id) async {
    try {
      await _dio.delete('/entregas/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
