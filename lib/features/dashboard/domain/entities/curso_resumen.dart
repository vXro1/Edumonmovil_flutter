/// Versión resumida de Curso — solo lo que necesitan
/// las cards de dashboard. La entidad Curso completa (con módulos,
/// participantes, etc.) está en la feature Cursos.
class CursoResumen {
  const CursoResumen({
    required this.id,
    required this.nombre,
    this.docenteNombre,
    this.imagenUrl,
    this.totalParticipantes = 0,
  });

  final String id;
  final String nombre;
  final String? docenteNombre;
  final String? imagenUrl;
  final int totalParticipantes;
}
