import 'dart:typed_data';

import '../entities/entrega.dart';

/// Enlace externo de una entrega (Entrega.js real: {url, titulo, descripcion}).
class EnlaceEntrega {
  const EnlaceEntrega({required this.url, this.titulo});

  final String url;
  final String? titulo;

  Map<String, dynamic> toJson() => {'url': url, if (titulo != null && titulo!.isNotEmpty) 'titulo': titulo};
}

class ArchivoUpload {
  const ArchivoUpload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.4.5-3.4.7 / FASE 10.5,
/// verificado contra entregaController.js real.
abstract class EntregasRepository {
  /// GET /entregas/tarea/:tareaId — excluye borradores (solo enviada/tarde/
  /// calificada) y trae las estadísticas ya calculadas por el backend.
  Future<({List<Entrega> items, EntregasEstadisticas stats})> fetchEntregasPorTarea(String tareaId);

  /// GET /entregas/mis-entregas/:tareaId — la entrega activa del padre
  /// autenticado para esa tarea (o null si todavía no la creó).
  Future<Entrega?> fetchMiEntrega(String tareaId);

  Future<Entrega> crearBorrador({
    required String tareaId,
    required String padreId,
    String? textoRespuesta,
    List<ArchivoUpload>? archivos,
    List<EnlaceEntrega>? enlaces,
  });

  Future<Entrega> actualizarBorrador({
    required String id,
    String? textoRespuesta,
    List<ArchivoUpload>? archivosNuevos,
    List<EnlaceEntrega>? enlaces,
  });

  Future<void> enviarEntrega(String id);

  Future<void> calificarEntrega({required String id, required int valoracion, String? comentario});

  Future<void> deleteEntrega(String id);

  /// DELETE /entregas/:id/archivos/:archivoId real: quita un solo adjunto de
  /// una entrega en borrador (sin borrar la entrega completa).
  Future<Entrega> eliminarArchivoEntrega({required String id, required String archivoId});
}
