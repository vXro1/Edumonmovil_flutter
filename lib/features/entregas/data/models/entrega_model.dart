import '../../../../shared/models/archivo.dart';
import '../../domain/entities/entrega.dart';

class EntregaPadreModel {
  const EntregaPadreModel({required this.id, required this.nombre, this.apellido, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final String? avatarUrl;

  factory EntregaPadreModel.fromJson(Map<String, dynamic> json) {
    return EntregaPadreModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString(),
      // Mismo campo que en todo el resto del backend real (User.fotoPerfilUrl).
      avatarUrl: json['fotoPerfilUrl']?.toString(),
    );
  }

  EntregaPadre toEntity() => EntregaPadre(id: id, nombre: nombre, apellido: apellido, avatarUrl: avatarUrl);
}

class CalificacionModel {
  const CalificacionModel({required this.valoracion, this.comentario, this.fechaCalificacion});

  final int valoracion;
  final String? comentario;
  final DateTime? fechaCalificacion;

  /// Confirmado contra entregaController.js real: calificarEntrega guarda
  /// "valoracion" (no "nota" — esa duda del blueprint queda resuelta).
  factory CalificacionModel.fromJson(Map<String, dynamic> json) {
    final valor = json['valoracion'] ?? json['nota'];
    return CalificacionModel(
      valoracion: valor is num ? valor.toInt() : 0,
      comentario: json['comentario']?.toString(),
      fechaCalificacion: json['fechaCalificacion'] != null
          ? DateTime.tryParse(json['fechaCalificacion'].toString())
          : null,
    );
  }

  Calificacion toEntity() => Calificacion(valoracion: valoracion, comentario: comentario, fechaCalificacion: fechaCalificacion);
}

/// DTO — BLUEPRINT.md FASE 9.6, verificado contra entregaController.js real.
class EntregaModel {
  const EntregaModel({
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
  final EntregaPadreModel? padre;
  final String? textoRespuesta;
  final String estado;
  final List<Archivo> archivos;
  final DateTime? fechaEnvio;
  final CalificacionModel? calificacion;

  factory EntregaModel.fromJson(Map<String, dynamic> json) {
    final padreRaw = json['padreId'] ?? json['padre'];
    EntregaPadreModel? padre;
    String padreId;
    if (padreRaw is Map) {
      padre = EntregaPadreModel.fromJson(padreRaw as Map<String, dynamic>);
      padreId = padre.id;
    } else {
      padreId = (padreRaw ?? '').toString();
    }

    final tareaRaw = json['tareaId'];
    final tareaId = tareaRaw is Map ? (tareaRaw['id'] ?? tareaRaw['_id']).toString() : (tareaRaw ?? '').toString();

    // createEntrega/updateEntrega real guardan el array bajo "archivosAdjuntos",
    // no "archivos".
    final archivosRaw = json['archivosAdjuntos'] as List?;
    final archivos = (archivosRaw ?? const []).map((e) => Archivo.fromJson(e as Map<String, dynamic>)).toList();

    final calificacionRaw = json['calificacion'];

    return EntregaModel(
      id: (json['id'] ?? json['_id']).toString(),
      tareaId: tareaId,
      padreId: padreId,
      padre: padre,
      textoRespuesta: json['textoRespuesta']?.toString(),
      estado: json['estado']?.toString() ?? 'borrador',
      archivos: archivos,
      // createEntrega/enviarEntrega reales escriben la fecha bajo la clave
      // "fechaEntrega" (mismo nombre que el campo de vencimiento en Tarea,
      // pero acá significa "cuándo se envió esta entrega").
      fechaEnvio: json['fechaEntrega'] != null ? DateTime.tryParse(json['fechaEntrega'].toString()) : null,
      calificacion: calificacionRaw is Map ? CalificacionModel.fromJson(calificacionRaw as Map<String, dynamic>) : null,
    );
  }

  Entrega toEntity() => Entrega(
    id: id,
    tareaId: tareaId,
    padreId: padreId,
    padre: padre?.toEntity(),
    textoRespuesta: textoRespuesta,
    estado: estado,
    archivos: archivos,
    fechaEnvio: fechaEnvio,
    calificacion: calificacion?.toEntity(),
  );
}
