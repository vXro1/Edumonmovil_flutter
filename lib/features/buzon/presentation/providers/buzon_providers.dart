import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/buzon_publico_remote_datasource.dart';
import '../../data/datasources/buzon_remote_datasource.dart';
import '../../data/repositories/buzon_publico_repository_impl.dart';
import '../../data/repositories/buzon_repository_impl.dart';
import '../../domain/entities/mensaje_buzon.dart';
import '../../domain/repositories/buzon_publico_repository.dart';
import '../../domain/repositories/buzon_repository.dart';

final buzonRemoteDataSourceProvider = Provider<BuzonRemoteDataSource>((ref) {
  return BuzonRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final buzonRepositoryProvider = Provider<BuzonRepository>((ref) {
  return BuzonRepositoryImpl(ref.watch(buzonRemoteDataSourceProvider));
});

/// Usado por el dashboard de superadmin para el bloque "Buzón" embebido.
final buzonRecientesProvider = FutureProvider<List<MensajeBuzon>>((ref) {
  return ref.watch(buzonRepositoryProvider).fetchMensajes(limit: 5);
});

/// Formulario público de contacto del Home web — sin sesión, comparte el
/// mismo Dio base (las cookies de sesión simplemente no existen para un
/// visitante anónimo, el RefreshInterceptor queda inerte).
final buzonPublicoRepositoryProvider = Provider<BuzonPublicoRepository>((ref) {
  return BuzonPublicoRepositoryImpl(BuzonPublicoRemoteDataSource(ref.watch(apiClientProvider).dio));
});
