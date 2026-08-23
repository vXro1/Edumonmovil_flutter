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

/// Enlace nuevo a adjuntar (createTarea real los toma de `enlaces`,
/// updateTarea de `nuevosEnlaces`/`enlaces`).
class EnlaceInput {
  const EnlaceInput({required this.url, required this.nombre, this.descripcion});

  final String url;
  final String nombre;
  final String? descripcion;

  Map<String, dynamic> toJson() => {'url': url, 'nombre': nombre, if (descripcion != null) 'descripcion': descripcion};
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.4.4 / FASE 10.5, verificada
/// contra tareaController.js/tareaValidator.js/Tarea.js reales.
abstract class TareasRepository {
  Future<TareasPage> fetchTareas({String? cursoId, required int page, required int limit});

  Future<Tarea> fetchTareaById(String id);

  /// tareaController.js real ignora `docenteId` en el body — el docente
  /// titular se toma siempre del token de quien crea la tarea.
  /// [moduloId] es obligatorio en el backend (Tarea.js: `required`) — sin él
  /// el POST /tareas devuelve 400.
  Future<Tarea> createTarea({
    required String titulo,
    String? descripcion,
    required String cursoId,
    required String moduloId,
    DateTime? fechaEntrega,
    required AsignacionTipo asignacionTipo,
    required TipoEntrega tipoEntrega,
    List<String>? participantesSeleccionados,
    List<String>? etiquetas,
    String? criterios,
    List<ArchivoUpload>? archivos,
    List<EnlaceInput>? enlaces,
  });

  Future<Tarea> updateTarea({
    required String id,
    String? titulo,
    String? descripcion,
    String? moduloId,
    DateTime? fechaEntrega,
    AsignacionTipo? asignacionTipo,
    TipoEntrega? tipoEntrega,
    List<String>? participantesSeleccionados,
    List<String>? etiquetas,
    String? criterios,
    List<ArchivoUpload>? archivosNuevos,
    List<EnlaceInput>? enlacesNuevos,
    List<String>? archivosAEliminar,
  });

  Future<void> cerrarTarea(String id);

  Future<void> deleteTarea(String id);
}
