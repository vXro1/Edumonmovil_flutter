import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/docentes_remote_datasource.dart';
import '../../data/repositories/docentes_repository_impl.dart';
import '../../domain/repositories/docentes_repository.dart';

final docentesRemoteDataSourceProvider = Provider<DocentesRemoteDataSource>((ref) {
  return DocentesRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final docentesRepositoryProvider = Provider<DocentesRepository>((ref) {
  return DocentesRepositoryImpl(ref.watch(docentesRemoteDataSourceProvider));
});
