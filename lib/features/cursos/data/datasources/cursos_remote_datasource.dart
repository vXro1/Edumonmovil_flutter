import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/curso_model.dart';
import '../models/participante_model.dart';

/// Data source remoto — shapes verificados contra cursoController.js real.
class CursosRemoteDataSource {
  const CursosRemoteDataSource(this._dio);

  final Dio _dio;

  // getCursos real solo filtra por estado/docenteId, no por texto — no se
  // manda ningún parámetro de búsqueda (ver CursosScreen para el filtro cliente).
  Future<({List<CursoModel> items, bool hasMore})> fetchCursos({required int page, required int limit}) {
    return _fetchList('/cursos', {'page': page, 'limit': limit});
  }

  Future<({List<CursoModel> items, bool hasMore})> fetchMisCursos({required int page, required int limit}) {
    return _fetchList('/cursos/mis-cursos', {'page': page, 'limit': limit});
  }

  Future<({List<CursoModel> items, bool hasMore})> _fetchList(String path, Map<String, dynamic> query) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      final data = response.data as Map<String, dynamic>;
      final items = (data['cursos'] as List).map((e) => CursoModel.fromJson(e as Map<String, dynamic>)).toList();
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final hasMore = pagination?['hasNextPage'] == true;
      return (items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CursoModel> fetchCursoById(String id) async {
    try {
      final response = await _dio.get('/cursos/$id');
      final data = response.data as Map<String, dynamic>;
      return CursoModel.fromJson(data['curso'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CursoModel> createCurso({
    required String nombre,
    String? descripcion,
    required String docenteId,
    String? color,
    Uint8List? fotoPortadaBytes,
    String? fotoPortadaFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nombre': nombre,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'docenteId': docenteId,
        if (color != null && color.isNotEmpty) 'color': color,
        if (fotoPortadaBytes != null)
          'fotoPortada': MultipartFile.fromBytes(fotoPortadaBytes, filename: fotoPortadaFilename ?? 'portada.jpg'),
      });
      final response = await _dio.post('/cursos', data: formData);
      final data = response.data as Map<String, dynamic>;
      return CursoModel.fromJson(data['curso'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// cursoController.js real (pull 85fa452/e3e8d5a): updateCurso ya no permite
  /// reasignar docenteId ni institucionId — si vienen en el body se ignoran
  /// en silencio. No se manda más para no sugerir en el cliente una acción
  /// que el backend descarta sin avisar.
  Future<CursoModel> updateCurso({
    required String id,
    String? nombre,
    String? descripcion,
    String? color,
    Uint8List? fotoPortadaBytes,
    String? fotoPortadaFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nombre': ?nombre,
        'descripcion': ?descripcion,
        'color': ?color,
        if (fotoPortadaBytes != null)
          'fotoPortada': MultipartFile.fromBytes(fotoPortadaBytes, filename: fotoPortadaFilename ?? 'portada.jpg'),
      });
      final response = await _dio.put('/cursos/$id', data: formData);
      final data = response.data as Map<String, dynamic>;
      return CursoModel.fromJson(data['curso'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// archivarCurso real: 400 si ya está archivado, 403 si un docente intenta
  /// archivar un curso que no es suyo — ambos casos ya llegan como mensaje
  /// legible vía AppException.
  Future<void> archiveCurso(String id) async {
    try {
      await _dio.delete('/cursos/$id');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<ParticipanteModel>> fetchParticipantes(String cursoId, {int limit = 100}) async {
    try {
      final response = await _dio.get('/cursos/$cursoId/participantes', queryParameters: {'limit': limit});
      final data = response.data as Map<String, dynamic>;
      // getParticipantesCurso real: cada item viene FLAT (nombre/apellido/etiqueta
      // al mismo nivel, no anidado bajo "usuario") — ParticipanteModel ya lo soporta.
      return (data['participantes'] as List)
          .map((e) => ParticipanteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> addParticipante({
    required String cursoId,
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
  }) async {
    try {
      await _dio.post(
        '/cursos/$cursoId/participantes',
        // agregarParticipante real destructura "contraseña" (con ñ) del body
        // y cae a la cédula si no viene — se manda explícito por claridad.
        data: {'nombre': nombre, 'apellido': apellido, 'cedula': cedula, 'telefono': telefono, 'contraseña': cedula},
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> removeParticipante({required String cursoId, required String usuarioId}) async {
    try {
      await _dio.delete('/cursos/$cursoId/participantes/$usuarioId');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// registrarUsuariosMasivo real: {message, docente, resumen: {total,
  /// exitosos, errores, duplicados}, detalles: {exitosos, errores, duplicados}}
  /// — mismo shape que preregistrarDocentesCSV en institucionController.js.
  Future<({int total, int exitosos, int duplicados, int errores, List<CsvParticipanteItem> detallesErrores, List<CsvParticipanteItem> detallesDuplicados})>
  importParticipantesCsv({required String cursoId, required Uint8List bytes, required String filename}) async {
    try {
      final formData = FormData.fromMap({
        'archivoCSV': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post('/cursos/$cursoId/usuarios-masivo', data: formData);
      final data = response.data as Map<String, dynamic>;

      final resumen = data['resumen'] as Map<String, dynamic>? ?? const {};
      final detalles = data['detalles'] as Map<String, dynamic>? ?? const {};

      List<CsvParticipanteItem> parseItems(String key) {
        final raw = detalles[key];
        if (raw is! List) return const [];
        return raw.map((e) {
          final map = e as Map<String, dynamic>;
          return CsvParticipanteItem(
            nombre: (map['nombre'] ?? map['datos']?['nombre'] ?? '').toString(),
            cedula: (map['cedula'] ?? map['datos']?['cedula'] ?? '').toString(),
            motivo: (map['motivo'] ?? map['error'] ?? 'Error desconocido').toString(),
          );
        }).toList();
      }

      int asInt(dynamic v) => v is num ? v.toInt() : 0;

      return (
        total: asInt(resumen['total']),
        exitosos: asInt(resumen['exitosos']),
        duplicados: asInt(resumen['duplicados']),
        errores: asInt(resumen['errores']),
        detallesErrores: parseItems('errores'),
        detallesDuplicados: parseItems('duplicados'),
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

class CsvParticipanteItem {
  const CsvParticipanteItem({required this.nombre, required this.cedula, required this.motivo});

  final String nombre;
  final String cedula;
  final String motivo;
}
