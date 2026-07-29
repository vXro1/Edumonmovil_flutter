import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/perfiles_remote_datasource.dart';
import '../../data/repositories/perfiles_repository_impl.dart';
import '../../domain/repositories/perfiles_repository.dart';

final perfilesRemoteDataSourceProvider = Provider<PerfilesRemoteDataSource>((ref) {
  return PerfilesRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final perfilesRepositoryProvider = Provider<PerfilesRepository>((ref) {
  return PerfilesRepositoryImpl(ref.watch(perfilesRemoteDataSourceProvider));
});
