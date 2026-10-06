class PerfilActivo {
  const PerfilActivo({required this.id, required this.nombre, this.avatarUrl, required this.esTitular});

  final String id;
  final String nombre;
  final String? avatarUrl;
  final bool esTitular;
}
