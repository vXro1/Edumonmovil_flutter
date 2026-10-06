class MensajeBuzon {
  const MensajeBuzon({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.mensaje,
    this.telefono,
    this.institucion,
    this.leido = false,
    required this.createdAt,
  });

  final String id;
  final String nombre;
  final String correo;
  final String mensaje;
  final String? telefono;
  final String? institucion;
  final bool leido;
  final DateTime createdAt;
}
