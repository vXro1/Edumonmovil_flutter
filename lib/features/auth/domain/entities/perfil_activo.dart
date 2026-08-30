/// Perfil familiar activo en la sesión actual — BLUEPRINT.md FASE 3.7.1.
/// authController.js real (getProfile): junto a `user` siempre devuelve
/// `perfilActivo` con el perfil que está usando esta sesión ahora mismo (el
/// titular por defecto, o un perfil secundario si el JWT trae perfilId). Es
/// la única fuente de verdad de "qué perfil está seleccionado" — el listado
/// de GET /perfiles no lo indica (su `activo` es un flag de soft-delete, no
/// de selección).
class PerfilActivo {
  const PerfilActivo({required this.id, required this.nombre, this.avatarUrl, required this.esTitular});

  final String id;
  final String nombre;
  final String? avatarUrl;
  final bool esTitular;
}
