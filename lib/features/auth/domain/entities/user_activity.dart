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
