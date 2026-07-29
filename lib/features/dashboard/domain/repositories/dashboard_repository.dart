import '../entities/curso_resumen.dart';
import '../entities/institucion_resumen.dart';

/// Datos agregados para los 4 dashboards — BLUEPRINT.md FASE 3.2.
/// Cada método pega a un endpoint simple ya documentado en FASE 10 y deriva
/// el conteo/lista del propio resultado; no implica la feature completa
/// (Instituciones/Usuarios/Cursos), que llega en sprints posteriores.
abstract class DashboardRepository {
  Future<List<InstitucionResumen>> fetchInstituciones();

  Future<InstitucionResumen?> fetchMiInstitucion();

  Future<int> fetchUsersCount({String? rol});

  /// GET /cursos/mis-cursos — cursos donde el usuario autenticado participa
  /// (docente titular o padre inscrito).
  Future<List<CursoResumen>> fetchMisCursos({required int limit});

  /// GET /cursos — listado general (todos los cursos visibles para
  /// superadmin/administrador), distinto de "mis cursos".
  Future<List<CursoResumen>> fetchCursos({required int limit});
}
