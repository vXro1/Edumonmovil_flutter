/// Adjunto compartido tarea/entrega/foro/evento — BLUEPRINT.md FASE 9.7.
/// Verificado contra tareaController.js/entregaController.js reales: cada
/// dominio guarda el array bajo la clave "archivosAdjuntos" (no "archivos"),
/// y los nombres de los campos internos varían un poco entre Tarea
/// (nombre/formato/tamano) y Entrega (nombreOriginal/tipoArchivo/tamano).
class Archivo {
  const Archivo({
    required this.id,
    required this.url,
    required this.nombre,
    this.publicId,
    this.tipo,
    this.tamanoBytes,
    this.descripcion,
  });

  final String id;
  final String url;
  final String nombre;
  final String? publicId;
  // Tarea real distingue adjuntos tipo 'archivo' (subido, tiene publicId) de
  // tipo 'enlace' (URL externa, sin publicId) dentro del mismo array
  // archivosAdjuntos — este campo trae ese discriminador tal cual.
  final String? tipo;
  final int? tamanoBytes;

  /// Solo presente en adjuntos tipo 'enlace'.
  final String? descripcion;

  bool get esEnlace => tipo == 'enlace';

  factory Archivo.fromJson(Map<String, dynamic> json) {
    final tamanoRaw = json['tamanoBytes'] ?? json['tamano'];
    return Archivo(
      id: (json['id'] ?? json['_id'] ?? json['publicId'] ?? json['public_id'] ?? json['url']).toString(),
      url: (json['url'] ?? json['secure_url'])?.toString() ?? '',
      nombre: (json['nombre'] ?? json['nombreOriginal'] ?? json['original_filename'])?.toString() ?? 'Archivo',
      publicId: (json['publicId'] ?? json['public_id'])?.toString(),
      tipo: (json['tipo'] ?? json['tipoArchivo'] ?? json['mimetype'])?.toString(),
      tamanoBytes: tamanoRaw is num ? tamanoRaw.toInt() : null,
      descripcion: json['descripcion']?.toString(),
    );
  }
}
