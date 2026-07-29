import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/cursos_remote_datasource.dart';
import '../../data/datasources/modulos_remote_datasource.dart';
import '../../data/repositories/cursos_repository_impl.dart';
import '../../data/repositories/modulos_repository_impl.dart';
import '../../domain/entities/curso.dart';
import '../../domain/repositories/cursos_repository.dart';
import '../../domain/repositories/modulos_repository.dart';

final cursosRemoteDataSourceProvider = Provider<CursosRemoteDataSource>((ref) {
  return CursosRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final cursosRepositoryProvider = Provider<CursosRepository>((ref) {
  return CursosRepositoryImpl(ref.watch(cursosRemoteDataSourceProvider));
});

final modulosRemoteDataSourceProvider = Provider<ModulosRemoteDataSource>((ref) {
  return ModulosRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final modulosRepositoryProvider = Provider<ModulosRepository>((ref) {
  return ModulosRepositoryImpl(ref.watch(modulosRemoteDataSourceProvider));
});

/// Detalle de un curso puntual, usado por el Hub — se invalida tras editar.
final cursoDetailProvider = FutureProvider.family<Curso, String>((ref, cursoId) {
  return ref.watch(cursosRepositoryProvider).fetchCursoById(cursoId);
});
