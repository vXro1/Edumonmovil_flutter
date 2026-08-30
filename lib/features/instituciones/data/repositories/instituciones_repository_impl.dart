import '../../domain/entities/institucion.dart';
import '../../domain/repositories/instituciones_repository.dart';
import '../datasources/instituciones_remote_datasource.dart';

class InstitucionesRepositoryImpl implements InstitucionesRepository {
  const InstitucionesRepositoryImpl(this._remote);

  final InstitucionesRemoteDataSource _remote;

  @override
  Future<List<Institucion>> fetchInstituciones() async {
    final result = await _remote.fetchInstituciones();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
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
  }) async {
    final result = await _remote.createInstitucion(
      nombre: nombre,
      nit: nit,
      direccion: direccion,
      telefono: telefono,
      correo: correo,
      adminNombre: adminNombre,
      adminApellido: adminApellido,
      adminCedula: adminCedula,
      adminCorreo: adminCorreo,
      adminTelefono: adminTelefono,
    );
    return result.toEntity();
  }

  @override
  Future<Institucion> updateInstitucion({
    required String id,
    required String nombre,
    required String direccion,
    required String telefono,
    required String correo,
  }) async {
    final result = await _remote.updateInstitucion(
      id: id,
      nombre: nombre,
      direccion: direccion,
      telefono: telefono,
      correo: correo,
    );
    return result.toEntity();
  }

  @override
  Future<Institucion> cambiarEstadoInstitucion({required String id, required bool activo}) async {
    final result = await _remote.cambiarEstadoInstitucion(id: id, activo: activo);
    return result.toEntity();
  }
}
