import '../../domain/entities/modulo.dart';

class ModuloModel {
  const ModuloModel({
    required this.id,
    required this.cursoId,
    required this.titulo,
    this.descripcion,
    this.orden,
    this.estado = 'activo',
  });

  final String id;
  final String cursoId;
  final String titulo;
  final String? descripcion;
  final int? orden;
  final String estado;

  /// moduloController.js real: getModulosByCurso NO puebla cursoId (queda
  /// como string plano), pero create/updateModulo SÍ lo populan
  /// (.populate('cursoId', ...)) — llega como objeto en esos casos. Se
  /// soportan ambas formas.
  factory ModuloModel.fromJson(Map<String, dynamic> json) {
    final cursoIdRaw = json['cursoId'];
    final cursoId = cursoIdRaw is Map ? (cursoIdRaw['id'] ?? cursoIdRaw['_id']).toString() : (cursoIdRaw ?? '').toString();

    return ModuloModel(
      id: (json['id'] ?? json['_id']).toString(),
      cursoId: cursoId,
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      orden: json['orden'] is num ? (json['orden'] as num).toInt() : null,
      estado: json['estado']?.toString() ?? 'activo',
    );
  }

  Modulo toEntity() =>
      Modulo(id: id, cursoId: cursoId, titulo: titulo, descripcion: descripcion, orden: orden, estado: estado);
}
