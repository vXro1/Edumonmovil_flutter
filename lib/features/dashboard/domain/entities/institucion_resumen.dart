/// Versión resumida de Institución — BLUEPRINT.md FASE 9.2 — solo lo que
/// necesita el dashboard de superadmin. La feature Instituciones completa
/// llega en Sprint 3.
class InstitucionResumen {
  const InstitucionResumen({required this.id, required this.nombre, this.nit, this.direccion});

  final String id;
  final String nombre;
  final String? nit;
  final String? direccion;
}
