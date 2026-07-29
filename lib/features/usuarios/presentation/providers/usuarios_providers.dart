import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/usuarios_remote_datasource.dart';
import '../../data/repositories/usuarios_repository_impl.dart';
import '../../domain/repositories/usuarios_repository.dart';

final usuariosRemoteDataSourceProvider = Provider<UsuariosRemoteDataSource>((ref) {
  return UsuariosRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  return UsuariosRepositoryImpl(ref.watch(usuariosRemoteDataSourceProvider));
});
