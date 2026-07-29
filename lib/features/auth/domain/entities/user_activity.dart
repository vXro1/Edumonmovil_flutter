/// Fila de actividad de un usuario — solo visible para superadmin, vía
/// GET /users/sesiones/ultimas (getUltimasSesiones real, no el "sesiones por
/// dispositivo" que describía originalmente el blueprint).
class UserActivity {
  const UserActivity({
    required this.userId,
    required this.nombre,
    required this.rol,
    required this.estado,
    this.correo,
    this.ultimoAcceso,
  });

  final String userId;
  final String nombre;
  final String rol;
  final String estado;
  final String? correo;
  final DateTime? ultimoAcceso;
}
