import '../../domain/entities/curso_resumen.dart';

/// DTO — (⚠️) shape de /cursos/mis-cursos no verificado contra el backend
/// real (solo vimos userController/authController) — parseo defensivo con
/// los alias que documenta BLUEPRINT.md FASE 9.3 para imagenUrl.
class CursoResumenModel {
  const CursoResumenModel({
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

  factory CursoResumenModel.fromJson(Map<String, dynamic> json) {
    String? docenteNombre;
    final docente = json['docente'];
    if (docente is Map) {
      final nombre = docente['nombre']?.toString() ?? '';
      final apellido = docente['apellido']?.toString() ?? '';
      docenteNombre = '$nombre $apellido'.trim();
    } else if (docente is String) {
      docenteNombre = docente;
    }

    final participantes = json['participantes'];
    final totalParticipantes = json['totalParticipantes'] is num
        ? (json['totalParticipantes'] as num).toInt()
        : (participantes is List ? participantes.length : 0);

    return CursoResumenModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      docenteNombre: docenteNombre?.isEmpty == true ? null : docenteNombre,
      imagenUrl: (json['imagenUrl'] ?? json['imagen'] ?? json['fotoPortada'] ?? json['fotoPortadaUrl'])?.toString(),
      totalParticipantes: totalParticipantes,
    );
  }

  CursoResumen toEntity() => CursoResumen(
    id: id,
    nombre: nombre,
    docenteNombre: docenteNombre,
    imagenUrl: imagenUrl,
    totalParticipantes: totalParticipantes,
  );
}
