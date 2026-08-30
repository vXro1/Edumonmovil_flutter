import '../../domain/entities/perfil_activo.dart';

/// DTO — sub-objeto `perfilActivo` de GET /auth/profile (authController.js
/// real: getProfile), verificado contra el controller.
class PerfilActivoModel {
  const PerfilActivoModel({required this.id, required this.nombre, this.avatarUrl, required this.esTitular});

  final String id;
  final String nombre;
  final String? avatarUrl;
  final bool esTitular;

  factory PerfilActivoModel.fromJson(Map<String, dynamic> json) {
    return PerfilActivoModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      esTitular: json['esTitular'] == true,
    );
  }

  PerfilActivo toEntity() => PerfilActivo(id: id, nombre: nombre, avatarUrl: avatarUrl, esTitular: esTitular);
}
