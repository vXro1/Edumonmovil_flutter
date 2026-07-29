import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../eventos/presentation/providers/eventos_providers.dart';
import '../../tareas/presentation/providers/tareas_providers.dart';
import '../domain/entities/calendario_entry.dart';

/// Combina Tareas + Eventos en un único listado de entradas de calendario —
/// ver comentario en calendario_entry.dart sobre por qué no se llama a
/// /calendario/:cursoId directamente.
Future<List<CalendarioEntry>> loadCalendarioEntries(WidgetRef ref, {String? cursoId}) async {
  final tareasRepo = ref.read(tareasRepositoryProvider);
  final eventosRepo = ref.read(eventosRepositoryProvider);

  final tareasPage = await tareasRepo.fetchTareas(cursoId: cursoId, page: 1, limit: 200);
  final eventos = await eventosRepo.fetchEventos(cursoId: cursoId);

  final entries = <CalendarioEntry>[
    for (final t in tareasPage.items)
      if (t.fechaEntrega != null)
        CalendarioEntry(
          id: t.id,
          titulo: t.titulo,
          fecha: t.fechaEntrega!,
          tipo: CalendarioEntryTipo.tarea,
          cursoId: t.cursoId,
          cursoNombre: t.cursoNombre,
          vencida: t.vencida,
        ),
    for (final e in eventos)
      CalendarioEntry(
        id: e.id,
        titulo: e.titulo,
        fecha: e.fechaInicio,
        tipo: CalendarioEntryTipo.evento,
        categoria: e.categoria.label,
        cursoId: e.cursosIds.isNotEmpty ? e.cursosIds.first : null,
        vencida: false,
      ),
  ];
  entries.sort((a, b) => a.fecha.compareTo(b.fecha));
  return entries;
}
