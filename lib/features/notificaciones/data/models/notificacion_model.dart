import '../../domain/entities/notificacion.dart';

/// DTO — BLUEPRINT.md FASE 9.11.
/// Shape verificado contra notificacionController.js real (documento
/// `.lean()` de Mongoose): `{_id, titulo, mensaje, tipo, leido, fecha}`.
class NotificacionModel {
  const NotificacionModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.createdAt,
  });

  final String id;
  final String titulo;
  final String mensaje;
  final NotificacionTipo tipo;
  final bool leida;
  final DateTime createdAt;

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: (json['id'] ?? json['_id']).toString(),
      // Notificacion.js real no tiene `titulo`: se lee de metadata.titulo
      // (notificaciones enviadas desde la app) o se deriva del tipo, igual
      // que hace obtenerTitulo() del backend para push/email.
      titulo: _titulo(json),
      mensaje: (json['mensaje'] ?? json['descripcion'])?.toString() ?? '',
      tipo: NotificacionTipo.fromApiString(json['tipo']?.toString()),
      // El campo real es `leido` (ver query { leido: false } del controller),
      // no `leida` — con la key vieja esto siempre daba false y ninguna
      // notificación se mostraba jamás como leída.
      leida: json['leido'] == true,
      createdAt: (DateTime.tryParse((json['fecha'] ?? json['createdAt'])?.toString() ?? '') ?? DateTime.now()).toLocal(),
    );
  }

  static String _titulo(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    final desdeMetadata = metadata is Map ? metadata['titulo']?.toString().trim() : null;
    final directo = json['titulo']?.toString().trim();
    for (final t in [directo, desdeMetadata]) {
      if (t != null && t.isNotEmpty) return t;
    }
    return NotificacionTipo.fromApiString(json['tipo']?.toString()).tituloPorDefecto;
  }

  Notificacion toEntity() =>
      Notificacion(id: id, titulo: titulo, mensaje: mensaje, tipo: tipo, leida: leida, createdAt: createdAt);
}
