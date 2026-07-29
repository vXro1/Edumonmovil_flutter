import '../../../../shared/models/archivo.dart';

/// Calificación 1-5 estrellas, unificada en toda la app — decisión de
/// producto (la web original tenía dos escalas distintas: 1-5 en un flujo,
/// 0-100 en otro; se unificó a estrellas en la migración).
class Calificacion {
  const Calificacion({required this.valoracion, this.comentario, this.fechaCalificacion});

  final int valoracion;
  final String? comentario;
  final DateTime? fechaCalificacion;
}

/// Padre embebido en una Entrega — nombre reducido para evitar depender de
/// la entidad User completa acá.
class EntregaPadre {
  const EntregaPadre({required this.id, required this.nombre, this.apellido, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final String? avatarUrl;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

/// Conteos que devuelve getEntregasByTarea real junto con la lista —
/// se muestran tal cual en vez de recalcularlos en cliente porque el
/// endpoint pagina la lista de entregas y un conteo client-side subestimaría
/// el total.
class EntregasEstadisticas {
  const EntregasEstadisticas({this.total = 0, this.enviadas = 0, this.tarde = 0, this.valoradas = 0});

  final int total;
  final int enviadas;
  final int tarde;
  final int valoradas;
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.6, verificado contra entregaController.js real.
class Entrega {
  const Entrega({
    required this.id,
    required this.tareaId,
    required this.padreId,
    this.padre,
    this.textoRespuesta,
    this.estado = 'borrador',
    this.archivos = const [],
    this.fechaEnvio,
    this.calificacion,
  });

  final String id;
  final String tareaId;
  final String padreId;
  final EntregaPadre? padre;
  final String? textoRespuesta;
  final String estado; // borrador|enviada|tarde|calificada
  final List<Archivo> archivos;
  final DateTime? fechaEnvio;
  final Calificacion? calificacion;

  bool get esBorrador => estado == 'borrador';
  bool get calificada => calificacion != null;
}
