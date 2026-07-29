import '../../../auth/domain/entities/user.dart';

/// Curso N───N User vía tabla puente con "etiqueta" — BLUEPRINT.md FASE 9.15.
class Participante {
  const Participante({required this.user, this.etiqueta});

  final User user;
  final String? etiqueta; // docente|padre
}
