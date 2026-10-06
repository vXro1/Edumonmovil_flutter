class Modulo {
  const Modulo({
    required this.id,
    required this.cursoId,
    required this.titulo,
    this.descripcion,
    this.orden,
    this.estado = 'activo',
  });

  final String id;
  final String cursoId;
  final String titulo;
  final String? descripcion;
  final int? orden;
  // deleteModulo es soft-delete (estado: 'inactivo'), reversible vía
  // restoreModulo — no un borrado permanente.
  final String estado;

  bool get activo => estado != 'inactivo';
}
