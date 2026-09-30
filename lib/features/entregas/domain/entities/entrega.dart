import '../../../../shared/models/archivo.dart';

/// Calificación 1-5 estrellas, unificada en toda la app — decisión de
/// producto (la web original tenía dos escalas distintas: 1-5 en un flujo,
/// 0-100 en otro; se unificó a estrellas en la migración).
/// Entrega.js real: {valoracion, comentario, fechaCalificacion,
/// fechaUltimaModificacion, valoracionAnterior, docenteId}.
class Calificacion {
  const Calificacion({
    required this.valoracion,
    this.comentario,
    this.fechaCalificacion,
    this.fechaUltimaModificacion,
    this.valoracionAnterior,
    this.docenteNombre,
  });

  final int valoracion;

  /// Retroalimentación escrita del docente (máx. 1000 caracteres).
  final String? comentario;
  final DateTime? fechaCalificacion;
  final DateTime? fechaUltimaModificacion;
  final int? valoracionAnterior;
  final String? docenteNombre;

  bool get tieneComentario => comentario != null && comentario!.trim().isNotEmpty;

  static const etiquetas = ['', 'Necesita mejorar', 'Regular', 'Bien', 'Muy bien', 'Excelente'];

  String get etiqueta => valoracion >= 1 && valoracion <= 5 ? etiquetas[valoracion] : '';
}

/// Padre embebido en una Entrega — nombre reducido para evitar depender de
/// la entidad User completa acá.
class EntregaPadre {
  const EntregaPadre({required this.id, required this.nombre, this.apellido, this.avatarUrl, this.correo});

  final String id;
  final String nombre;
  final String? apellido;
  final String? avatarUrl;
  final String? correo;

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
    this.enlaces = const [],
    this.fechaEnvio,
    this.calificacion,
  });

  final String id;
  final String tareaId;
  final String padreId;
  final EntregaPadre? padre;
  final String? textoRespuesta;
  // entregaValidator.js real: solo borrador|enviada|tarde — "calificada" NO
  // es un valor de estado. Calificar es ortogonal al estado: [calificacion]
  // puede o no estar presente sobre 'enviada'/'tarde'.
  final String estado;
  final List<Archivo> archivos;

  /// Entrega.js real: enlaces externos {url, titulo, descripcion} —
  /// representados como Archivo tipo 'enlace' para reusar el visor.
  final List<Archivo> enlaces;
  final DateTime? fechaEnvio;
  final Calificacion? calificacion;

  bool get esBorrador => estado == 'borrador';
  bool get calificada => calificacion != null;
  bool get tieneContenido =>
      (textoRespuesta?.trim().isNotEmpty ?? false) || archivos.isNotEmpty || enlaces.isNotEmpty;

  /// Estado legible para el usuario (nunca el valor crudo del backend).
  String get estadoLabel {
    if (calificada) return 'Calificado';
    return switch (estado) {
      'enviada' => 'Entregado',
      'tarde' => 'Entregado tarde',
      _ => 'Borrador',
    };
  }
}
