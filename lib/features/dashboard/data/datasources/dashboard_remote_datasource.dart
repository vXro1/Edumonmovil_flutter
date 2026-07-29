import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/curso_resumen_model.dart';
import '../models/institucion_resumen_model.dart';

/// Data source remoto para los 4 dashboards — BLUEPRINT.md FASE 10.3 / 10.4 / 10.2.
class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  // Sin 'limit' explícito, el backend cae a la paginación por defecto (10 en
  // el resto de los listados verificados) — con más instituciones que eso,
  // el selector de "Institución" en usuario_form_screen.dart podía traer un
  // initialValue que no estaba entre los items cargados y Flutter tira el
  // assertion 'There should be exactly one item with value...'. Se pide un
  // límite alto para que en la práctica siempre entren todas.
  Future<List<InstitucionResumenModel>> fetchInstituciones() async {
    try {
      final response = await _dio.get('/instituciones', queryParameters: {'limit': 200});
      final data = response.data;
      final rawList = data is List
          ? data
          : (data is Map ? (data['instituciones'] ?? data['data']) as List? : null);
      return (rawList ?? const [])
          .map((e) => InstitucionResumenModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<InstitucionResumenModel?> fetchMiInstitucion() async {
    try {
      final response = await _dio.get('/instituciones/mi-institucion');
      final data = response.data;
      final json = data is Map ? (data['institucion'] ?? data) as Map<String, dynamic> : null;
      return json != null ? InstitucionResumenModel.fromJson(json) : null;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// GET /users?rol=X&limit=1 — solo nos interesa pagination.totalUsers,
  /// shape confirmada contra userController.js real.
  Future<int> fetchUsersCount({String? rol}) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {'limit': 1, 'rol': ?rol},
      );
      final pagination = (response.data as Map)['pagination'] as Map<String, dynamic>?;
      final total = pagination?['totalUsers'];
      return total is num ? total.toInt() : 0;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<CursoResumenModel>> fetchMisCursos({required int limit}) async {
    try {
      final response = await _dio.get('/cursos/mis-cursos', queryParameters: {'limit': limit});
      return _parseCursos(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<CursoResumenModel>> fetchCursos({required int limit}) async {
    try {
      final response = await _dio.get('/cursos', queryParameters: {'limit': limit});
      return _parseCursos(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  List<CursoResumenModel> _parseCursos(dynamic data) {
    final rawList = data is List ? data : (data is Map ? (data['cursos'] ?? data['data']) as List? : null);
    return (rawList ?? const []).map((e) => CursoResumenModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
