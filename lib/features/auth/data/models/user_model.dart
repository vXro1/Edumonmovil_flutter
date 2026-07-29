import '../../../../core/security/role.dart';
import '../../domain/entities/user.dart';

/// DTO — BLUEPRINT.md FASE 9.1, verificado contra authController.js/userController.js reales.
class UserModel {
  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.estado,
    required this.cedula,
    required this.telefono,
    this.avatarUrl,
    this.correo,
    this.institucionId,
    this.permisos = const [],
    this.ultimoAcceso,
    this.fechaRegistro,
    this.primerInicioSesion = false,
  });

  final String id;
  final String nombre;
  final String apellido;
  final UserRole rol;
  final String estado;
  final String cedula;
  final String telefono;
  final String? avatarUrl;
  final String? correo;
  final String? institucionId;
  final List<String> permisos;
  final DateTime? ultimoAcceso;
  final DateTime? fechaRegistro;
  final bool primerInicioSesion;

  /// Sirve tanto para las respuestas envueltas de auth ({user: {...}}, ya
  /// desenvueltas antes de llamar acá) como para los documentos Mongoose
  /// crudos que devuelven getUsers/getUserById/createUser/updateUser
  /// (userController.js real) — ambos comparten el mismo shape de campos.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      rol: UserRole.fromApiString(json['rol'].toString()),
      estado: json['estado']?.toString() ?? 'activo',
      cedula: json['cedula']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      // El backend real (login/getProfile) manda "fotoPerfilUrl", no "avatarUrl".
      avatarUrl: json['fotoPerfilUrl']?.toString(),
      correo: json['correo']?.toString(),
      institucionId: json['institucionId']?.toString(),
      permisos: (json['permisos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      ultimoAcceso: json['ultimoAcceso'] != null ? DateTime.tryParse(json['ultimoAcceso'].toString()) : null,
      fechaRegistro: json['fechaRegistro'] != null ? DateTime.tryParse(json['fechaRegistro'].toString()) : null,
      primerInicioSesion: json['primerInicioSesion'] == true,
    );
  }

  User toEntity() => User(
        id: id,
        nombre: nombre,
        apellido: apellido,
        rol: rol,
        estado: estado,
        cedula: cedula,
        telefono: telefono,
        avatarUrl: avatarUrl,
        correo: correo,
        institucionId: institucionId,
        permisos: permisos,
        ultimoAcceso: ultimoAcceso,
        fechaRegistro: fechaRegistro,
        primerInicioSesion: primerInicioSesion,
      );
}
