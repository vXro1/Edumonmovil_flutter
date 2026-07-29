import 'dart:typed_data';

import '../entities/foro.dart';

class ArchivoUpload {
  const ArchivoUpload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.4.8 / 3.8.3 / FASE 10.6.
/// (⚠️) No vimos foroController.js/mensajeForoController.js reales — shapes
/// inferidos del blueprint.
abstract class ForosRepository {
  Future<List<Foro>> fetchForosPorCurso(String cursoId);

  Future<Foro> fetchForoById(String id);

  Future<Foro> createForo({
    required String titulo,
    String? descripcion,
    required String cursoId,
    bool publico = false,
    List<ArchivoUpload>? archivos,
  });

  Future<void> toggleEstadoForo({required String id, required bool cerrado});

  Future<void> deleteForo(String id);

  Future<List<MensajeForo>> fetchMensajes(String foroId);

  Future<MensajeForo> enviarMensaje({
    required String foroId,
    required String contenido,
    String? respuestaA,
    List<ArchivoUpload>? archivos,
  });

  Future<void> toggleLike(String mensajeId);

  Future<void> editarMensaje({required String id, required String contenido});

  Future<void> deleteMensaje(String id);
}
