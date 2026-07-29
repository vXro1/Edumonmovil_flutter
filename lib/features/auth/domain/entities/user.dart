import '../../../../core/security/role.dart';

/// Entidad de dominio User — BLUEPRINT.md FASE 9.1.
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
  // Usados por la feature Usuarios (Sprint 3) — no siempre presentes en las
  // respuestas de auth (login/profile), por eso son opcionales acá.
  final DateTime? ultimoAcceso;
  final DateTime? fechaRegistro;

  /// authController.js real: getProfile también devuelve este campo (además
  /// de login) — se necesita acá para poder restaurarlo al reabrir la app
  /// (ver AuthController._restoreSession).
  final bool primerInicioSesion;

  String get nombreCompleto => '$nombre $apellido';
}
