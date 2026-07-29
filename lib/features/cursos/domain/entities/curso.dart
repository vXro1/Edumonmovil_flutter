/// Docente titular embebido en un Curso — nombre reducido para evitar
/// depender de la entidad User completa acá.
class CursoDocente {
  const CursoDocente({required this.id, required this.nombre, this.apellido});

  final String id;
  final String nombre;
  final String? apellido;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.3, verificada contra
/// cursoController.js real.
class Curso {
  const Curso({
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
  final CursoDocente? docente;
  final String? docenteId;
  final int totalParticipantes;
  final DateTime? fechaCreacion;

  /// Hex opcional (#RGB o #RRGGBB) — cursoController.js real, agregado en el
  /// pull 85fa452/e3e8d5a. Se usa para pintar la tarjeta/encabezado del curso.
  final String? color;

  bool get archivado => estado == 'archivado';
}
