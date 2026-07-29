import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/foros_remote_datasource.dart';
import '../../data/repositories/foros_repository_impl.dart';
import '../../domain/repositories/foros_repository.dart';

final forosRemoteDataSourceProvider = Provider<ForosRemoteDataSource>((ref) {
  return ForosRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final forosRepositoryProvider = Provider<ForosRepository>((ref) {
  return ForosRepositoryImpl(ref.watch(forosRemoteDataSourceProvider));
});
