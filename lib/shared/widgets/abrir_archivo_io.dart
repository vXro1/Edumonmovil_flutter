import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda los bytes ya descargados (con la sesión de la app) en un temporal y
/// los abre con la app del sistema — los adjuntos privados de entregas no se
/// pueden abrir pasando la URL a otra app, porque exigen la cookie de sesión.
/// Devuelve un mensaje de error, o null si se abrió.
Future<String?> abrirArchivoLocal(Uint8List bytes, String nombre, String url) async {
  final dir = await getTemporaryDirectory();
  final seguro = nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File('${dir.path}/edumon_adjuntos/$seguro');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path);
  if (result.type == ResultType.done) return null;
  if (result.type == ResultType.noAppToOpen) return 'No hay ninguna aplicación instalada para abrir este archivo.';
  return 'No se pudo abrir el archivo.';
}
