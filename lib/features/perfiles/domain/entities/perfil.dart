/// Entidad de dominio — BLUEPRINT.md FASE 9.13.
/// (⚠️) No vimos perfilFamiliarController.js real — shapes inferidos del
/// blueprint.
class Perfil {
  const Perfil({
    required this.id,
    required this.nombre,
    this.avatarUrl,
    this.esTitular = false,
    this.esActivo = false,
  });

  final String id;
  final String nombre;
  final String? avatarUrl;
  final bool esTitular;
  final bool esActivo;
}
