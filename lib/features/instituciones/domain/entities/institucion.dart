/// Info del admin embebida — institucionController.js real puebla
/// adminId vía .populate('adminId', 'nombre apellido correo'), así que
/// siempre llega como objeto, nunca como id suelto.
/// (⚠️) Ese .populate() real NO incluye fotoPerfilUrl en el select — avatarUrl
/// va a quedar null hasta que el backend agregue ese campo al populate.
/// Se deja el campo listo del lado cliente para que funcione apenas se corrija.
class InstitucionAdmin {
  const InstitucionAdmin({required this.id, required this.nombre, required this.apellido, this.correo, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final String? correo;
  final String? avatarUrl;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.2, verificada contra
/// institucionController.js real.
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
}
