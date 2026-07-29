import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/tareas_remote_datasource.dart';
import '../../data/repositories/tareas_repository_impl.dart';
import '../../domain/entities/tarea.dart';
import '../../domain/repositories/tareas_repository.dart';

final tareasRemoteDataSourceProvider = Provider<TareasRemoteDataSource>((ref) {
  return TareasRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final tareasRepositoryProvider = Provider<TareasRepository>((ref) {
  return TareasRepositoryImpl(ref.watch(tareasRemoteDataSourceProvider));
});

/// Retos activos (ni cerrados ni vencidos) — usado por el dashboard de
/// docente para la stat card + sección "Retos activos".
final tareasActivasProvider = FutureProvider<List<Tarea>>((ref) async {
  final page = await ref.watch(tareasRepositoryProvider).fetchTareas(page: 1, limit: 50);
  return page.items.where((t) => !t.cerrada && !t.vencida).toList();
});
