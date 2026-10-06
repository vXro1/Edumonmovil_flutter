/// Versión resumida de Institución — solo lo que
/// necesita el dashboard de superadmin. La entidad completa está en la
/// feature Instituciones.
class InstitucionResumen {
  const InstitucionResumen({required this.id, required this.nombre, this.nit, this.direccion});

  final String id;
  final String nombre;
  final String? nit;
  final String? direccion;
}
