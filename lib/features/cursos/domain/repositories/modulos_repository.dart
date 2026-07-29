import '../entities/modulo.dart';

/// Interfaz de dominio — BLUEPRINT.md FASE 3.4.3, verificada contra
/// moduloController.js real.
abstract class ModulosRepository {
  Future<List<Modulo>> fetchModulos(String cursoId, {bool incluirInactivos = false});

  Future<Modulo> createModulo({required String cursoId, required String titulo, String? descripcion});

  Future<Modulo> updateModulo({required String id, required String titulo, String? descripcion});

  /// deleteModulo real: soft-delete (estado: 'inactivo'), reversible con [restoreModulo].
  Future<void> deleteModulo(String id);

  Future<void> restoreModulo(String id);
}
