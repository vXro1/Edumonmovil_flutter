import '../../domain/entities/institucion.dart';

class InstitucionAdminModel {
  const InstitucionAdminModel({required this.id, required this.nombre, this.apellido, this.correo, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final String? correo;
  final String? avatarUrl;

  factory InstitucionAdminModel.fromJson(Map<String, dynamic> json) {
    return InstitucionAdminModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString(),
      correo: json['correo']?.toString(),
      // Ver comentario en institucion.dart: el .populate() real hoy no trae
      // este campo — queda listo para cuando el backend lo agregue.
      avatarUrl: json['fotoPerfilUrl']?.toString(),
    );
  }

  InstitucionAdmin toEntity() =>
      InstitucionAdmin(id: id, nombre: nombre, apellido: apellido, correo: correo, avatarUrl: avatarUrl);
}

class InstitucionModel {
  const InstitucionModel({
    required this.id,
    required this.nombre,
    this.nit,
    this.codigo,
    this.direccion,
    this.telefono,
    this.correo,
    this.admin,
  });

  final String id;
  final String nombre;
  final String? nit;
  final String? codigo;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final InstitucionAdminModel? admin;

  /// institucionController.js real: adminId siempre viene populado
  /// (.populate('adminId', 'nombre apellido correo')) como objeto o null,
  /// nunca como id suelto — a diferencia de institucionId en User.
  factory InstitucionModel.fromJson(Map<String, dynamic> json) {
    final adminRaw = json['adminId'];
    return InstitucionModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      nit: json['nit']?.toString(),
      codigo: json['codigo']?.toString(),
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      correo: json['correo']?.toString(),
      admin: adminRaw is Map ? InstitucionAdminModel.fromJson(adminRaw as Map<String, dynamic>) : null,
    );
  }

  Institucion toEntity() => Institucion(
    id: id,
    nombre: nombre,
    nit: nit,
    codigo: codigo,
    direccion: direccion,
    telefono: telefono,
    correo: correo,
    admin: admin?.toEntity(),
  );
}
