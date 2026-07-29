import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/instituciones_remote_datasource.dart';
import '../../data/repositories/instituciones_repository_impl.dart';
import '../../domain/entities/institucion.dart';
import '../../domain/repositories/instituciones_repository.dart';

final institucionesRemoteDataSourceProvider = Provider<InstitucionesRemoteDataSource>((ref) {
  return InstitucionesRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final institucionesRepositoryProvider = Provider<InstitucionesRepository>((ref) {
  return InstitucionesRepositoryImpl(ref.watch(institucionesRemoteDataSourceProvider));
});

final institucionesListProvider = FutureProvider<List<Institucion>>((ref) {
  return ref.watch(institucionesRepositoryProvider).fetchInstituciones();
});
