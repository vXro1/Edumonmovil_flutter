import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/entities/calendario_entry.dart';
import 'datasources/calendario_remote_datasource.dart';

final calendarioRemoteDataSourceProvider = Provider<CalendarioRemoteDataSource>((ref) {
  return CalendarioRemoteDataSource(ref.watch(apiClientProvider).dio);
});

/// Carga el calendario desde los endpoints reales de calendarioController.js
/// — [cursoId] null trae el agregado de todos los cursos del usuario
/// (GET /calendario/calendario); con [cursoId] trae solo ese curso
/// (GET /calendario/:cursoId). Reemplaza la agregación anterior que combinaba
/// TareasRepository.fetchTareas + EventosRepository.fetchEventos a mano en
/// el cliente (ver historial: se hacía así porque no se conocía el shape
/// real de este endpoint).
Future<List<CalendarioEntry>> loadCalendarioEntries(WidgetRef ref, {String? cursoId}) async {
  final datasource = ref.read(calendarioRemoteDataSourceProvider);
  final entries = cursoId != null
      ? await datasource.fetchCalendarioCurso(cursoId)
      : await datasource.fetchCalendarioUsuario();
  return entries..sort((a, b) => a.fecha.compareTo(b.fecha));
}
