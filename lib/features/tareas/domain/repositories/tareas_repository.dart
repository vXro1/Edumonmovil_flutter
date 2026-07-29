import 'dart:typed_data';

import '../entities/tarea.dart';

class TareasPage {
  const TareasPage({required this.items, required this.hasMore});

  final List<Tarea> items;
  final bool hasMore;
}

class ArchivoUpload {
  const ArchivoUpload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.4.4 / FASE 10.5.
/// (⚠️) No vimos tareaController.js real — shapes inferidos del blueprint.
abstract class TareasRepository {
  Future<TareasPage> fetchTareas({String? cursoId, required int page, required int limit});

  Future<Tarea> fetchTareaById(String id);

  /// tareaController.js real ignora `docenteId` en el body — el docente
  /// titular se toma siempre del token de quien crea la tarea.
  Future<Tarea> createTarea({
    required String titulo,
    String? descripcion,
    required String cursoId,
    String? moduloId,
    DateTime? fechaEntrega,
    required AsignacionTipo asignacionTipo,
    required TipoEntrega tipoEntrega,
    List<String>? participantesSeleccionados,
    List<ArchivoUpload>? archivos,
  });

  Future<Tarea> updateTarea({
    required String id,
    String? titulo,
    String? descripcion,
    DateTime? fechaEntrega,
    AsignacionTipo? asignacionTipo,
    TipoEntrega? tipoEntrega,
    List<String>? participantesSeleccionados,
    List<ArchivoUpload>? archivosNuevos,
  });

  Future<void> cerrarTarea(String id);

  Future<void> deleteTarea(String id);
}
