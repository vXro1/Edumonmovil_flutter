import '../../domain/entities/padre_info.dart';

/// DTO — getPadreInfo real (userController.js), respuesta anidada bajo `padre`.
class PadreInfoModel {
  const PadreInfoModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    this.correo,
    this.telefono,
    this.avatarUrl,
    required this.estado,
    required this.esTitular,
    this.ultimoAcceso,
    this.fechaRegistro,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String? correo;
  final String? telefono;
  final String? avatarUrl;
  final String estado;
  final bool esTitular;
  final DateTime? ultimoAcceso;
  final DateTime? fechaRegistro;

  factory PadreInfoModel.fromJson(Map<String, dynamic> json) {
    return PadreInfoModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      cedula: json['cedula']?.toString() ?? '',
      correo: json['correo']?.toString(),
      telefono: json['telefono']?.toString(),
      avatarUrl: json['fotoPerfilUrl']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      esTitular: json['esTitular'] == true,
      ultimoAcceso: json['ultimoAcceso'] != null ? DateTime.tryParse(json['ultimoAcceso'].toString()) : null,
      fechaRegistro: json['fechaRegistro'] != null ? DateTime.tryParse(json['fechaRegistro'].toString()) : null,
    );
  }

  PadreInfo toEntity() => PadreInfo(
    id: id,
    nombre: nombre,
    apellido: apellido,
    cedula: cedula,
    correo: correo,
    telefono: telefono,
    avatarUrl: avatarUrl,
    estado: estado,
    esTitular: esTitular,
    ultimoAcceso: ultimoAcceso,
    fechaRegistro: fechaRegistro,
  );
}
