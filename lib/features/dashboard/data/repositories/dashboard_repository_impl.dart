import '../../domain/entities/curso_resumen.dart';
import '../../domain/entities/institucion_resumen.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<List<InstitucionResumen>> fetchInstituciones() async {
    final result = await _remote.fetchInstituciones();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<InstitucionResumen?> fetchMiInstitucion() async {
    final result = await _remote.fetchMiInstitucion();
    return result?.toEntity();
  }

  @override
  Future<int> fetchUsersCount({String? rol}) => _remote.fetchUsersCount(rol: rol);

  @override
  Future<List<CursoResumen>> fetchMisCursos({required int limit}) async {
    final result = await _remote.fetchMisCursos(limit: limit);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<CursoResumen>> fetchCursos({required int limit}) async {
    final result = await _remote.fetchCursos(limit: limit);
    return result.map((e) => e.toEntity()).toList();
  }
}
