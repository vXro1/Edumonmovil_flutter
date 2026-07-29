import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/curso_resumen.dart';
import '../../domain/entities/institucion_resumen.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final institucionesProvider = FutureProvider<List<InstitucionResumen>>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchInstituciones();
});

final miInstitucionProvider = FutureProvider<InstitucionResumen?>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchMiInstitucion();
});

final usersCountProvider = FutureProvider.family<int, String?>((ref, rol) {
  return ref.watch(dashboardRepositoryProvider).fetchUsersCount(rol: rol);
});

final misCursosProvider = FutureProvider.family<List<CursoResumen>, int>((ref, limit) {
  return ref.watch(dashboardRepositoryProvider).fetchMisCursos(limit: limit);
});

final cursosProvider = FutureProvider.family<List<CursoResumen>, int>((ref, limit) {
  return ref.watch(dashboardRepositoryProvider).fetchCursos(limit: limit);
});
