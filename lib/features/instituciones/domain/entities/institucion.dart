class InstitucionAdmin {
  const InstitucionAdmin({required this.id, required this.nombre, required this.apellido, this.correo, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final String? correo;
  final String? avatarUrl;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

class Institucion {
  const Institucion({
    required this.id,
    required this.nombre,
    this.nit,
    this.codigo,
    this.direccion,
    this.telefono,
    this.correo,
    this.admin,
    this.activo = true,
  });

  final String id;
  final String nombre;
  final String? nit;
  // Código autogenerado por el backend, distinto del NIT (usado p.ej. para
  // el correo de fallback del admin: `${cedula}@${codigo}.edu`).
  final String? codigo;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final InstitucionAdmin? admin;

  final bool activo;
}
