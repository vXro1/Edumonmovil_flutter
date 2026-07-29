import 'dart:typed_data';

class CsvImportItem {
  const CsvImportItem({required this.nombre, required this.cedula, required this.motivo});

  final String nombre;
  final String cedula;
  final String motivo;
}

/// Resultado real de POST /instituciones/docentes/csv (preregistrarDocentesCSV):
/// {resumen: {total, exitosos, duplicados, errores}, detalles: {exitosos, errores, duplicados}}.
class CsvImportResult {
  const CsvImportResult({
    required this.total,
    required this.exitosos,
    required this.duplicados,
    required this.errores,
    required this.detallesErrores,
    required this.detallesDuplicados,
  });

  final int total;
  final int exitosos;
  final int duplicados;
  final int errores;
  final List<CsvImportItem> detallesErrores;
  final List<CsvImportItem> detallesDuplicados;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.3.3, verificada contra
/// institucionController.js real (preregistrarDocente/preregistrarDocentesCSV).
abstract class DocentesRepository {
  /// [correo] es opcional — si se omite, el backend genera `${cedula}@temp.com`.
  Future<void> createDocente({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    String? correo,
  });

  Future<CsvImportResult> importCsv({required Uint8List bytes, required String filename});
}
