import '../../domain/entities/curso.dart';

class CursoDocenteModel {
  const CursoDocenteModel({required this.id, required this.nombre, this.apellido});

  final String id;
  final String nombre;
  final String? apellido;

  factory CursoDocenteModel.fromJson(Map<String, dynamic> json) {
    return CursoDocenteModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString(),
    );
  }

  CursoDocente toEntity() => CursoDocente(id: id, nombre: nombre, apellido: apellido);
}

/// DTO — BLUEPRINT.md FASE 9.3, verificado contra cursoController.js real.
/// "docente" llega poblado (create/getCursos/getMisCursos/getCursoById
/// siempre corren formatearDocente); "docenteId" queda como fallback por si
/// algún endpoint futuro no lo formatea.
class CursoModel {
  const CursoModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
    this.imagenUrl,
    this.docente,
    this.docenteId,
    this.totalParticipantes = 0,
    this.fechaCreacion,
    this.color,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String estado;
  final String? imagenUrl;
  final CursoDocenteModel? docente;
  final String? docenteId;
  final int totalParticipantes;
  final DateTime? fechaCreacion;
  final String? color;

  factory CursoModel.fromJson(Map<String, dynamic> json) {
    final docenteRaw = json['docente'];
    CursoDocenteModel? docente;
    String? docenteId;
    if (docenteRaw is Map) {
      docente = CursoDocenteModel.fromJson(docenteRaw as Map<String, dynamic>);
      docenteId = docente.id;
    } else if (docenteRaw is String) {
      docenteId = docenteRaw;
    }
    docenteId ??= json['docenteId']?.toString();

    // participantes real: [{usuarioId, etiqueta}, ...] — cuenta directa de la lista.
    final participantes = json['participantes'];
    final totalParticipantes = participantes is List ? participantes.length : 0;

    return CursoModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      imagenUrl: json['fotoPortadaUrl']?.toString(),
      docente: docente,
      docenteId: docenteId,
      totalParticipantes: totalParticipantes,
      fechaCreacion: json['fechaCreacion'] != null ? DateTime.tryParse(json['fechaCreacion'].toString()) : null,
      color: json['color']?.toString(),
    );
  }

  Curso toEntity() => Curso(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    estado: estado,
    imagenUrl: imagenUrl,
    docente: docente?.toEntity(),
    docenteId: docenteId,
    totalParticipantes: totalParticipantes,
    fechaCreacion: fechaCreacion,
    color: color,
  );
}
