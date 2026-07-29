import '../../domain/entities/perfil.dart';

/// DTO — BLUEPRINT.md FASE 9.13, (⚠️) shape inferido del blueprint.
class PerfilModel {
  const PerfilModel({
    required this.id,
    required this.nombre,
    this.avatarUrl,
    this.esTitular = false,
    this.esActivo = false,
  });

  final String id;
  final String nombre;
  final String? avatarUrl;
  final bool esTitular;
  final bool esActivo;

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      avatarUrl: (json['avatarUrl'] ?? json['fotoPerfilUrl'])?.toString(),
      esTitular: json['esTitular'] == true,
      esActivo: json['esActivo'] == true || json['activo'] == true,
    );
  }

  Perfil toEntity() => Perfil(id: id, nombre: nombre, avatarUrl: avatarUrl, esTitular: esTitular, esActivo: esActivo);
}
