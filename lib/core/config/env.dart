/// Configuración de entorno de la app.
///
/// El base URL se resuelve en tiempo de build vía `--dart-define=API_BASE_URL=...`.
/// Sin ese flag, apunta al backend de producción real (Render).
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-edumon.onrender.com/api',
  );

  /// Origen del backend SIN el sufijo "/api" — cloudinaryUpload.js real
  /// migró de Cloudinary a almacenamiento local en disco: `url` ahora es
  /// una ruta relativa servida desde la raíz del backend (`/uploads/...`,
  /// `/static/avatares/...`), no desde `/api`, y nunca una URL absoluta
  /// como las de Cloudinary. Sin esto, cualquier imagen/adjunto de la app
  /// (avatares, portadas de curso, adjuntos de tareas/entregas/foros/
  /// eventos) le llega a Flutter como "/uploads/pub/..." y no se puede
  /// resolver (no hay concepto de "página actual" como en un navegador).
  static String get _serverOrigin {
    final sinApi = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return sinApi;
  }

  /// Resuelve una URL que puede venir relativa (almacenamiento local real,
  /// "/uploads/...") o absoluta (Cloudinary legacy o ya completa,
  /// "https://...") a una URL siempre usable por Image.network/Dio. Nulo o
  /// vacío se deja pasar tal cual para que el caller decida el fallback.
  static String? resolveUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return url.startsWith('/') ? '$_serverOrigin$url' : '$_serverOrigin/$url';
  }
}
