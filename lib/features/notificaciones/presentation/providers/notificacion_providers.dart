import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notificacion_remote_datasource.dart';
import '../../data/repositories/notificacion_repository_impl.dart';
import '../../domain/repositories/notificacion_repository.dart';

final notificacionRemoteDataSourceProvider = Provider<NotificacionRemoteDataSource>((ref) {
  return NotificacionRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return NotificacionRepositoryImpl(ref.watch(notificacionRemoteDataSourceProvider));
});

/// Conteo de no leídas para el badge del AppBar — BLUEPRINT.md FASE 5.2
/// (FutureProvider + ref.invalidate(), equivalente al staleTime de TanStack
/// Query). Se invalida tras marcar como leída/leídas desde la lista.
final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificacionRepositoryProvider).fetchUnreadCount();
});
