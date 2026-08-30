import '../entities/institucion.dart';

/// Interfaz de dominio — BLUEPRINT.md FASE 3.3.1, verificada contra
/// institucionController.js real.
abstract class InstitucionesRepository {
  Future<List<Institucion>> fetchInstituciones();

  Future<Institucion> createInstitucion({
    required String nombre,
    required String nit,
    required String direccion,
    required String telefono,
    required String correo,
    required String adminNombre,
    required String adminApellido,
    required String adminCedula,
    required String adminCorreo,
    required String adminTelefono,
  });

  Future<Institucion> updateInstitucion({
    required String id,
    required String nombre,
    required String direccion,
    required String telefono,
    required String correo,
  });

  /// PATCH /instituciones/:id/estado real — ver nota en el datasource sobre
  /// por qué esto no está conectado a ningún botón de UI todavía.
  Future<Institucion> cambiarEstadoInstitucion({required String id, required bool activo});
}
