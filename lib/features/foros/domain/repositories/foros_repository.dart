import 'dart:typed_data';

import '../entities/foro.dart';
import '../entities/foro_dashboard.dart';

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

  /// GET /foros/:id/dashboard real — analíticas del foro (mensajes
  /// recientes, participantes activos, estadísticas, actividad 7 días).
  Future<ForoDashboard> fetchDashboard(String foroId);

  /// crearForoValidator real: descripcion es obligatoria (10-2000 caracteres).
  Future<Foro> createForo({
    required String titulo,
    required String descripcion,
    required String cursoId,
    bool publico = false,
    List<ArchivoUpload>? archivos,
  });

  /// actualizarForo real: solo título/descripción/público — no soporta
  /// reemplazar archivos, y el estado (abrir/cerrar) va por su propia acción.
  Future<Foro> updateForo({required String id, String? titulo, String? descripcion, bool? publico});

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
