import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tareas/presentation/providers/tareas_providers.dart';
import '../../data/datasources/entregas_remote_datasource.dart';
import '../../data/repositories/entregas_repository_impl.dart';
import '../../domain/repositories/entregas_repository.dart';

final entregasRemoteDataSourceProvider = Provider<EntregasRemoteDataSource>((ref) {
  return EntregasRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final entregasRepositoryProvider = Provider<EntregasRepository>((ref) {
  return EntregasRepositoryImpl(ref.watch(entregasRemoteDataSourceProvider));
});

/// Entregas pendientes (rol padre) — mismo criterio que MisEntregasScreen:
/// sin entregaController.js real que exponga un conteo agregado por padre
/// (ver comentario en mis_entregas_screen.dart), se cuenta combinando
/// fetchTareas + fetchMiEntrega por cada una.
final entregasPendientesCountProvider = FutureProvider<int>((ref) async {
  final tareasPage = await ref.watch(tareasRepositoryProvider).fetchTareas(page: 1, limit: 50);
  final entregasRepo = ref.watch(entregasRepositoryProvider);
  var pendientes = 0;
  for (final tarea in tareasPage.items) {
    final entrega = await entregasRepo.fetchMiEntrega(tarea.id);
    if (entrega == null || entrega.esBorrador) pendientes++;
  }
  return pendientes;
});
