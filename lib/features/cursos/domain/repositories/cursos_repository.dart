import 'dart:typed_data';

import '../entities/curso.dart';
import '../entities/participante.dart';

class CursosPage {
  const CursosPage({required this.items, required this.hasMore});

  final List<Curso> items;
  final bool hasMore;
}

class ParticipanteImportItem {
  const ParticipanteImportItem({required this.nombre, required this.cedula, required this.motivo});

  final String nombre;
  final String cedula;
  final String motivo;
}

/// registrarUsuariosMasivo real distingue tres categorías, no dos: exitosos,
/// duplicados (cédula/correo ya existente) y errores (falla real).
class ParticipantesImportResult {
  const ParticipantesImportResult({
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
  final List<ParticipanteImportItem> detallesErrores;
  final List<ParticipanteImportItem> detallesDuplicados;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.4, verificada contra
/// cursoController.js/moduloController.js reales.
abstract class CursosRepository {
  // getCursos real no soporta búsqueda por texto (solo estado/docenteId) —
  // el filtro de texto en la UI se hace en cliente, ver CursosScreen.
  Future<CursosPage> fetchCursos({required int page, required int limit});

  Future<CursosPage> fetchMisCursos({required int page, required int limit});

  Future<Curso> fetchCursoById(String id);

  Future<Curso> createCurso({
    required String nombre,
    String? descripcion,
    required String docenteId,
    String? color,
    Uint8List? fotoPortadaBytes,
    String? fotoPortadaFilename,
  });

  /// docenteId ya no es editable acá — cursoController.js real lo ignora si
  /// viene en el body (ver CursosRemoteDataSource.updateCurso).
  Future<Curso> updateCurso({
    required String id,
    String? nombre,
    String? descripcion,
    String? color,
    Uint8List? fotoPortadaBytes,
    String? fotoPortadaFilename,
  });

  /// DELETE /cursos/:id real: archiva (soft-delete), no elimina.
  Future<void> archiveCurso(String id);

  /// PATCH /cursos/:id/restaurar real: revierte el archivado.
  Future<void> restoreCurso(String id);

  Future<List<Participante>> fetchParticipantes(String cursoId, {int limit});

  Future<void> addParticipante({
    required String cursoId,
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
  });

  Future<void> removeParticipante({required String cursoId, required String usuarioId});

  Future<ParticipantesImportResult> importParticipantesCsv({
    required String cursoId,
    required Uint8List bytes,
    required String filename,
  });
}
