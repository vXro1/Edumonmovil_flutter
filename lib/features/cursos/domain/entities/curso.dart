/// Docente titular embebido en un Curso — nombre reducido para evitar
/// depender de la entidad User completa acá.
class CursoDocente {
  const CursoDocente({required this.id, required this.nombre, this.apellido});

  final String id;
  final String nombre;
  final String? apellido;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

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

  final String? color;

  bool get archivado => estado == 'archivado';
}
