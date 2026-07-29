import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/mensaje_buzon_model.dart';

/// Data source remoto — BLUEPRINT.md FASE 10.8.
/// (⚠️) No vimos buzonController.js real — shapes inferidos del blueprint.
class BuzonRemoteDataSource {
  const BuzonRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MensajeBuzonModel>> fetchMensajes({int limit = 50}) async {
    try {
      final response = await _dio.get('/buzon', queryParameters: {'limit': limit});
      final data = response.data;
      final rawList = data is List ? data : (data is Map ? (data['mensajes'] ?? data['data']) as List? : null);
      return (rawList ?? const []).map((e) => MensajeBuzonModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> marcarLeido(String id) async {
    try {
      await _dio.patch('/buzon/$id/leido');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
