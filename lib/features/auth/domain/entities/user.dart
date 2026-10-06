import '../../../../core/security/role.dart';

/// Entidad de dominio User
class User {
  const User({
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
  // Usados por la feature Usuarios — no siempre presentes en las
  // respuestas de auth (login/profile), por eso son opcionales acá.
  final DateTime? ultimoAcceso;
  final DateTime? fechaRegistro;

  final bool primerInicioSesion;

  String get nombreCompleto => '$nombre $apellido';
}
