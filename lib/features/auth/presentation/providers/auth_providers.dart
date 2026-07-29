import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_controller.dart';

export 'auth_controller.dart' show authControllerProvider, AuthController, AuthState, AuthStatus;

/// El ApiClient sólo referencia authControllerProvider dentro del closure de
/// onUnauthorized (invocado cuando el refresh de sesión falla, no durante la
/// construcción) — evita el ciclo apiClient→auth→apiClient en la inicialización.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    cookieJar: ref.watch(cookieJarProvider),
    onUnauthorized: () => ref.read(authControllerProvider.notifier).forceLogout(),
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});
