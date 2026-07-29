import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/eventos_remote_datasource.dart';
import '../../data/repositories/eventos_repository_impl.dart';
import '../../domain/entities/evento.dart';
import '../../domain/repositories/eventos_repository.dart';

final eventosRemoteDataSourceProvider = Provider<EventosRemoteDataSource>((ref) {
  return EventosRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final eventosRepositoryProvider = Provider<EventosRepository>((ref) {
  return EventosRepositoryImpl(ref.watch(eventosRemoteDataSourceProvider));
});

/// Usado por los 4 dashboards para la stat card + sección "Eventos de hoy".
final eventosHoyProvider = FutureProvider<List<Evento>>((ref) {
  return ref.watch(eventosRepositoryProvider).fetchEventosHoy();
});
