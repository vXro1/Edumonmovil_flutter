import '../../../../shared/models/archivo.dart';

enum AsignacionTipo { todos, seleccionados }

enum TipoEntrega { archivo, texto, enlace, multimedia, presencial, grupal }

extension TipoEntregaX on TipoEntrega {
  String get apiValue => name;

  String get label {
    switch (this) {
      case TipoEntrega.archivo:
        return 'Archivo';
      case TipoEntrega.texto:
        return 'Texto';
      case TipoEntrega.enlace:
        return 'Enlace';
      case TipoEntrega.multimedia:
        return 'Multimedia';
      case TipoEntrega.presencial:
        return 'Presencial';
      case TipoEntrega.grupal:
        return 'Grupal';
    }
  }

  static TipoEntrega fromApiString(String? raw) {
    return TipoEntrega.values.firstWhere((t) => t.name == raw, orElse: () => TipoEntrega.archivo);
  }
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.5, verificada contra
/// tareaController.js/Tarea.js reales.
class Tarea {
  const Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.estado = 'publicada',
    this.fechaEntrega,
    required this.cursoId,
    this.cursoNombre,
    this.moduloId,
    this.asignacionTipo = AsignacionTipo.todos,
    this.tipoEntrega = TipoEntrega.archivo,
    this.participantesSeleccionados = const [],
    this.archivos = const [],
    this.etiquetas = const [],
    this.criterios,
    this.totalEntregas = 0,
    this.totalPendientes = 0,
    this.totalCalificadas = 0,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  // Tarea.js real: enum ["publicada", "cerrada"], default "publicada" — NO
  // "activa" (BUG REAL corregido: con 'activa' como valor esperado, `vencida`
  // nunca daba true porque el backend jamás manda ese string, así que ningún
  // reto vencido se marcaba como tal en ninguna pantalla).
  final String estado;
  final DateTime? fechaEntrega;
  final String cursoId;
  final String? cursoNombre;
  final String? moduloId;
  final AsignacionTipo asignacionTipo;
  final TipoEntrega tipoEntrega;
  final List<String> participantesSeleccionados;
  final List<Archivo> archivos;
  final List<String> etiquetas;
  final String? criterios;
  final int totalEntregas;
  final int totalPendientes;
  final int totalCalificadas;

  /// Regla de negocio a portar siempre en cliente — BLUEPRINT.md FASE 9.5.
  bool get vencida => estado == 'publicada' && fechaEntrega != null && fechaEntrega!.isBefore(DateTime.now());

  bool get cerrada => estado == 'cerrada';
}
