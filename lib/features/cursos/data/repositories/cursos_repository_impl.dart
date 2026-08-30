import 'dart:typed_data';

import '../../domain/entities/curso.dart';
import '../../domain/entities/participante.dart';
import '../../domain/repositories/cursos_repository.dart';
import '../datasources/cursos_remote_datasource.dart';

class CursosRepositoryImpl implements CursosRepository {
  const CursosRepositoryImpl(this._remote);

  final CursosRemoteDataSource _remote;

  @override
  Future<CursosPage> fetchCursos({required int page, required int limit}) async {
    final result = await _remote.fetchCursos(page: page, limit: limit);
    return CursosPage(items: result.items.map((e) => e.toEntity()).toList(), hasMore: result.hasMore);
  }

  @override
  Future<CursosPage> fetchMisCursos({required int page, required int limit}) async {
    final result = await _remote.fetchMisCursos(page: page, limit: limit);
    return CursosPage(items: result.items.map((e) => e.toEntity()).toList(), hasMore: result.hasMore);
  }

  @override
  Future<Curso> fetchCursoById(String id) async {
    final result = await _remote.fetchCursoById(id);
    return result.toEntity();
  }

  @override
  Future<Curso> createCurso({
    required String nombre,
    String? descripcion,
    required String docenteId,
    String? color,
    Uint8List? fotoPortadaBytes,
    String? fotoPortadaFilename,
  }) async {
    final result = await _remote.createCurso(
      nombre: nombre,
      descripcion: descripcion,
      docenteId: docenteId,
      color: color,
      fotoPortadaBytes: fotoPortadaBytes,
      fotoPortadaFilename: fotoPortadaFilename,
    );
    return result.toEntity();
  }

  @override
  Future<Curso> updateCurso({
    required String id,
    String? nombre,
    String? descripcion,
    String? color,
    Uint8List? fotoPortadaBytes,
    String? fotoPortadaFilename,
  }) async {
    final result = await _remote.updateCurso(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      color: color,
      fotoPortadaBytes: fotoPortadaBytes,
      fotoPortadaFilename: fotoPortadaFilename,
    );
    return result.toEntity();
  }

  @override
  Future<void> archiveCurso(String id) => _remote.archiveCurso(id);

  @override
  Future<void> restoreCurso(String id) => _remote.restoreCurso(id);

  @override
  Future<List<Participante>> fetchParticipantes(String cursoId, {int limit = 100}) async {
    final result = await _remote.fetchParticipantes(cursoId, limit: limit);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> addParticipante({
    required String cursoId,
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
  }) {
    return _remote.addParticipante(cursoId: cursoId, nombre: nombre, apellido: apellido, cedula: cedula, telefono: telefono);
  }

  @override
  Future<void> removeParticipante({required String cursoId, required String usuarioId}) {
    return _remote.removeParticipante(cursoId: cursoId, usuarioId: usuarioId);
  }

  @override
  Future<ParticipantesImportResult> importParticipantesCsv({
    required String cursoId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final result = await _remote.importParticipantesCsv(cursoId: cursoId, bytes: bytes, filename: filename);
    return ParticipantesImportResult(
      total: result.total,
      exitosos: result.exitosos,
      duplicados: result.duplicados,
      errores: result.errores,
      detallesErrores: result.detallesErrores
          .map((e) => ParticipanteImportItem(nombre: e.nombre, cedula: e.cedula, motivo: e.motivo))
          .toList(),
      detallesDuplicados: result.detallesDuplicados
          .map((e) => ParticipanteImportItem(nombre: e.nombre, cedula: e.cedula, motivo: e.motivo))
          .toList(),
    );
  }
}
