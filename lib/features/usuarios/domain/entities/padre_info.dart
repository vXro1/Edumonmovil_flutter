/// Info detallada de un padre/acudiente — GET /users/padre/:padreId/info
/// real (userController.js: getPadreInfo).
class PadreInfo {
  const PadreInfo({
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

  String get nombreCompleto => '$nombre $apellido';
}
