import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../domain/repositories/docentes_repository.dart';

/// Data source remoto — shapes verificados contra institucionController.js real.
class DocentesRemoteDataSource {
  const DocentesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> createDocente({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    String? correo,
  }) async {
    try {
      await _dio.post(
        '/instituciones/docentes',
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'cedula': cedula,
          'telefono': telefono,
          if (correo != null && correo.isNotEmpty) 'correo': correo,
        },
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// preregistrarDocentesCSV real: multer .single(...) — el nombre exacto
  /// del campo no está confirmado (no vimos institucionRoutes.js), se usa
  /// "archivoCSV" siguiendo el nombre documentado en el blueprint.
  Future<CsvImportResult> importCsv({required Uint8List bytes, required String filename}) async {
    try {
      final formData = FormData.fromMap({
        'archivoCSV': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post('/instituciones/docentes/csv', data: formData);
      final data = response.data as Map<String, dynamic>;

      final resumen = data['resumen'] as Map<String, dynamic>? ?? const {};
      final detalles = data['detalles'] as Map<String, dynamic>? ?? const {};

      List<CsvImportItem> parseItems(String key) {
        final raw = detalles[key];
        if (raw is! List) return const [];
        return raw.map((e) {
          final map = e as Map<String, dynamic>;
          return CsvImportItem(
            nombre: (map['nombre'] ?? map['datos']?['nombre'] ?? '').toString(),
            cedula: (map['cedula'] ?? map['datos']?['cedula'] ?? '').toString(),
            motivo: (map['motivo'] ?? map['error'] ?? 'Error desconocido').toString(),
          );
        }).toList();
      }

      int asInt(dynamic v) => v is num ? v.toInt() : 0;

      return CsvImportResult(
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
