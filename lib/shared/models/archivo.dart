import '../../core/config/env.dart';

/// Adjunto compartido tarea/entrega/foro/evento. Cada
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
    this.formato,
    this.tamanoBytes,
    this.descripcion,
    this.privado = false,
  });

  final String id;
  final String url;
  final String nombre;
  final String? publicId;
  // Tarea real distingue adjuntos tipo 'archivo' (subido, tiene publicId) de
  // tipo 'enlace' (URL externa, sin publicId) dentro del mismo array
  // archivosAdjuntos — este campo trae ese discriminador tal cual. En Entrega
  // es el mimetype (tipoArchivo) y en Foro/MensajeForo es imagen|video|pdf.
  final String? tipo;

  /// Extensión guardada por el backend en Tarea (`formato`, ej. "webp").
  final String? formato;
  final int? tamanoBytes;

  /// Solo presente en adjuntos tipo 'enlace'.
  final String? descripcion;

  /// Entrega: adjunto bajo /uploads/priv, solo se sirve con sesión.
  final bool privado;

  bool get esEnlace => tipo == 'enlace';

  static const _extImagen = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'};
  static const _extVideo = {'mp4', 'mov', 'avi', 'mpeg', 'webm', 'mkv', '3gp'};

  /// Extensión efectiva: formato del backend, o la del nombre/url.
  String get extension {
    final f = formato?.toLowerCase().replaceAll('.', '');
    if (f != null && f.isNotEmpty) return f;
    for (final s in [Uri.tryParse(url)?.path ?? url, nombre]) {
      final i = s.lastIndexOf('.');
      if (i != -1 && i < s.length - 1) return s.substring(i + 1).toLowerCase();
    }
    return '';
  }

  String get _tipoLower => (tipo ?? '').toLowerCase();

  bool get esImagen =>
      !esEnlace && (_tipoLower == 'imagen' || _tipoLower.startsWith('image/') || _extImagen.contains(extension));

  bool get esVideo =>
      !esEnlace && (_tipoLower == 'video' || _tipoLower.startsWith('video/') || _extVideo.contains(extension));

  bool get esPdf => !esEnlace && (_tipoLower == 'pdf' || _tipoLower == 'application/pdf' || extension == 'pdf');

  String? get tamanoLegible {
    final b = tamanoBytes;
    if (b == null || b <= 0) return null;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Archivo.fromJson(Map<String, dynamic> json) {
    final tamanoRaw = json['tamanoBytes'] ?? json['tamano'];
    return Archivo(
      id: (json['id'] ?? json['_id'] ?? json['publicId'] ?? json['public_id'] ?? json['url']).toString(),
      url: Env.resolveUrl((json['url'] ?? json['secure_url'])?.toString()) ?? '',
      nombre: (json['nombre'] ?? json['nombreOriginal'] ?? json['original_filename'])?.toString() ?? 'Archivo',
      publicId: (json['publicId'] ?? json['public_id'])?.toString(),
      tipo: (json['tipo'] ?? json['tipoArchivo'] ?? json['mimetype'])?.toString(),
      formato: json['formato']?.toString(),
      tamanoBytes: tamanoRaw is num ? tamanoRaw.toInt() : null,
      descripcion: json['descripcion']?.toString(),
      privado: json['privado'] == true,
    );
  }
}
