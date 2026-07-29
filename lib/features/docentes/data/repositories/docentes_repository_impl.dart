import 'dart:typed_data';

import '../../domain/repositories/docentes_repository.dart';
import '../datasources/docentes_remote_datasource.dart';

class DocentesRepositoryImpl implements DocentesRepository {
  const DocentesRepositoryImpl(this._remote);

  final DocentesRemoteDataSource _remote;

  @override
  Future<void> createDocente({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    String? correo,
  }) {
    return _remote.createDocente(nombre: nombre, apellido: apellido, cedula: cedula, telefono: telefono, correo: correo);
  }

  @override
  Future<CsvImportResult> importCsv({required Uint8List bytes, required String filename}) {
    return _remote.importCsv(bytes: bytes, filename: filename);
  }
}
