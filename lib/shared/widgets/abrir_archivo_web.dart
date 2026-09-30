import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

/// En web el navegador ya tiene la cookie de sesión del backend, así que
/// basta con abrir la URL en otra pestaña.
Future<String?> abrirArchivoLocal(Uint8List bytes, String nombre, String url) async {
  final ok = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  return ok ? null : 'No se pudo abrir el archivo.';
}
