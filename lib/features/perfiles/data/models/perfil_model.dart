import '../../domain/entities/perfil.dart';

/// DTO — verificado contra perfilFamiliarController.js real.
class PerfilModel {
  const PerfilModel({required this.id, required this.nombre, this.avatarUrl, this.esTitular = false});

  final String id;
  final String nombre;
  final String? avatarUrl;
  final bool esTitular;

  /// getMisPerfiles real (`GET /perfiles`) devuelve `{titular, perfiles}` —
  /// el titular es un objeto SEPARADO, no un elemento más del array
  /// `perfiles`. Este factory parsea un ítem cualquiera de cualquiera de los
  /// dos; `esTitular` no siempre viene en el JSON del array `perfiles` (los
  /// PerfilFamiliar crudos no tienen ese campo), así que [esTitularFallback]
  /// permite que el caller lo fije explícitamente al armar la lista.
  factory PerfilModel.fromJson(Map<String, dynamic> json, {bool esTitularFallback = false}) {
    return PerfilModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      avatarUrl: (json['avatarUrl'] ?? json['fotoPerfilUrl'])?.toString(),
      esTitular: json['esTitular'] == true || esTitularFallback,
    );
  }

  // NOTA: no hay campo `esActivo` acá a propósito. El `activo` que trae el
  // PerfilFamiliar crudo es un flag de soft-delete (todo perfil devuelto por
  // getMisPerfiles tiene activo:true), no "es el perfil seleccionado ahora".
  // Ese dato solo vive en `perfilActivo` de GET /auth/profile — ver
  // PerfilesRepositoryImpl.fetchPerfiles, que lo cruza con este id.
  Perfil toEntity({required bool esActivo}) =>
      Perfil(id: id, nombre: nombre, avatarUrl: avatarUrl, esTitular: esTitular, esActivo: esActivo);
}
