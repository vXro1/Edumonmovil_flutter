import '../../../../shared/models/archivo.dart';
import '../../domain/entities/tarea.dart';

/// DTO — BLUEPRINT.md FASE 9.5, verificado contra tareaController.js real.
class TareaModel {
  const TareaModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.estado = 'publicada',
    this.fechaEntrega,
    required this.cursoId,
    this.cursoNombre,
    this.moduloId,
    this.asignacionTipo = AsignacionTipo.todos,
    this.tipoEntrega = TipoEntrega.archivo,
    this.participantesSeleccionados = const [],
    this.archivos = const [],
    this.etiquetas = const [],
    this.criterios,
    this.totalEntregas = 0,
    this.totalPendientes = 0,
    this.totalCalificadas = 0,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final String estado;
  final DateTime? fechaEntrega;
  final String cursoId;
  final String? cursoNombre;
  final String? moduloId;
  final AsignacionTipo asignacionTipo;
  final TipoEntrega tipoEntrega;
  final List<String> participantesSeleccionados;
  final List<Archivo> archivos;
  final List<String> etiquetas;
  final String? criterios;
  final int totalEntregas;
  final int totalPendientes;
  final int totalCalificadas;

  factory TareaModel.fromJson(Map<String, dynamic> json) {
    final cursoRaw = json['cursoId'];
    String cursoId;
    String? cursoNombre;
    if (cursoRaw is Map) {
      cursoId = (cursoRaw['id'] ?? cursoRaw['_id']).toString();
      cursoNombre = cursoRaw['nombre']?.toString();
    } else {
      cursoId = (cursoRaw ?? '').toString();
      cursoNombre = json['cursoNombre']?.toString();
    }

    final moduloRaw = json['moduloId'];
    final moduloId = moduloRaw is Map ? (moduloRaw['id'] ?? moduloRaw['_id'])?.toString() : moduloRaw?.toString();

    final participantesRaw = json['participantesSeleccionados'] as List?;
    final participantes = (participantesRaw ?? const [])
        .map((e) => e is Map ? (e['id'] ?? e['_id']).toString() : e.toString())
        .toList();

    // createTarea/updateTarea real guardan el array bajo "archivosAdjuntos",
    // no "archivos" — incluye tanto tipo:'archivo' como tipo:'enlace'.
    final archivosRaw = json['archivosAdjuntos'] as List?;
    final archivos = (archivosRaw ?? const []).map((e) => Archivo.fromJson(e as Map<String, dynamic>)).toList();

    final etiquetasRaw = json['etiquetas'] as List?;
    final etiquetas = (etiquetasRaw ?? const []).map((e) => e.toString()).toList();

    return TareaModel(
      id: (json['id'] ?? json['_id']).toString(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      estado: json['estado']?.toString() ?? 'publicada',
      fechaEntrega: json['fechaEntrega'] != null ? DateTime.tryParse(json['fechaEntrega'].toString()) : null,
      cursoId: cursoId,
      cursoNombre: cursoNombre,
      moduloId: moduloId,
      asignacionTipo: json['asignacionTipo'] == 'seleccionados' ? AsignacionTipo.seleccionados : AsignacionTipo.todos,
      tipoEntrega: TipoEntregaX.fromApiString(json['tipoEntrega']?.toString()),
      participantesSeleccionados: participantes,
      archivos: archivos,
      etiquetas: etiquetas,
      criterios: json['criterios']?.toString(),
      totalEntregas: json['totalEntregas'] is num ? (json['totalEntregas'] as num).toInt() : 0,
      totalPendientes: json['totalPendientes'] is num ? (json['totalPendientes'] as num).toInt() : 0,
      totalCalificadas: json['totalCalificadas'] is num ? (json['totalCalificadas'] as num).toInt() : 0,
    );
  }

  Tarea toEntity() => Tarea(
    id: id,
    titulo: titulo,
    descripcion: descripcion,
    estado: estado,
    fechaEntrega: fechaEntrega,
    cursoId: cursoId,
    cursoNombre: cursoNombre,
    moduloId: moduloId,
    asignacionTipo: asignacionTipo,
    tipoEntrega: tipoEntrega,
    participantesSeleccionados: participantesSeleccionados,
    archivos: archivos,
    etiquetas: etiquetas,
    criterios: criterios,
    totalEntregas: totalEntregas,
    totalPendientes: totalPendientes,
    totalCalificadas: totalCalificadas,
  );
}
