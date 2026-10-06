import '../../../../core/config/env.dart';
import '../../../../shared/models/archivo.dart';
import '../../domain/entities/entrega.dart';

DateTime? _fecha(dynamic raw) => raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();

class EntregaPadreModel {
  const EntregaPadreModel({required this.id, required this.nombre, this.apellido, this.avatarUrl, this.correo});

  final String id;
  final String nombre;
  final String? apellido;
  final String? avatarUrl;
  final String? correo;

  factory EntregaPadreModel.fromJson(Map<String, dynamic> json) {
    return EntregaPadreModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString(),
      // Mismo campo que en todo el resto del backend (User.fotoPerfilUrl).
      avatarUrl: Env.resolveUrl(json['fotoPerfilUrl']?.toString()),
      correo: json['correo']?.toString(),
    );
  }

  EntregaPadre toEntity() =>
      EntregaPadre(id: id, nombre: nombre, apellido: apellido, avatarUrl: avatarUrl, correo: correo);
}

class CalificacionModel {
  const CalificacionModel({
    required this.valoracion,
    this.comentario,
    this.fechaCalificacion,
    this.fechaUltimaModificacion,
    this.valoracionAnterior,
    this.docenteNombre,
  });

  final int valoracion;
  final String? comentario;
  final DateTime? fechaCalificacion;
  final DateTime? fechaUltimaModificacion;
  final int? valoracionAnterior;
  final String? docenteNombre;

  /// calificarEntrega guarda "valoracion" (1-5), "comentario" (retroalimentación) y el
  /// docente que calificó en "docenteId" (populado con nombre/apellido).
  factory CalificacionModel.fromJson(Map<String, dynamic> json) {
    final valor = json['valoracion'] ?? json['nota'];
    final anterior = json['valoracionAnterior'];
    final docenteRaw = json['docenteId'];
    String? docenteNombre;
    if (docenteRaw is Map) {
      docenteNombre = '${docenteRaw['nombre'] ?? ''} ${docenteRaw['apellido'] ?? ''}'.trim();
      if (docenteNombre.isEmpty) docenteNombre = null;
    }
    return CalificacionModel(
      valoracion: valor is num ? valor.toInt() : int.tryParse(valor?.toString() ?? '') ?? 0,
      comentario: json['comentario']?.toString(),
      fechaCalificacion: _fecha(json['fechaCalificacion']),
      fechaUltimaModificacion: _fecha(json['fechaUltimaModificacion']),
      valoracionAnterior: anterior is num ? anterior.toInt() : null,
      docenteNombre: docenteNombre,
    );
  }

  Calificacion toEntity() => Calificacion(
    valoracion: valoracion,
    comentario: comentario,
    fechaCalificacion: fechaCalificacion,
    fechaUltimaModificacion: fechaUltimaModificacion,
    valoracionAnterior: valoracionAnterior,
    docenteNombre: docenteNombre,
  );
}

class EntregaModel {
  const EntregaModel({
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
  final EntregaPadreModel? padre;
  final String? textoRespuesta;
  final String estado;
  final List<Archivo> archivos;
  final List<Archivo> enlaces;
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

    // createEntrega/updateEntrega guardan el array bajo "archivosAdjuntos",
    // no "archivos".
    final archivosRaw = json['archivosAdjuntos'] as List?;
    final archivos = (archivosRaw ?? const []).map((e) => Archivo.fromJson(e as Map<String, dynamic>)).toList();

    final enlacesRaw = json['enlaces'] as List?;
    final enlaces = (enlacesRaw ?? const []).whereType<Map>().map((e) {
      final url = e['url']?.toString() ?? '';
      final titulo = e['titulo']?.toString();
      return Archivo(
        id: url,
        url: url,
        nombre: titulo != null && titulo.trim().isNotEmpty ? titulo : url,
        tipo: 'enlace',
        descripcion: e['descripcion']?.toString(),
      );
    }).toList();

    final calificacionRaw = json['calificacion'];
    final calificacion = calificacionRaw is Map ? CalificacionModel.fromJson(calificacionRaw.cast<String, dynamic>()) : null;

    return EntregaModel(
      id: (json['id'] ?? json['_id']).toString(),
      tareaId: tareaId,
      padreId: padreId,
      padre: padre,
      textoRespuesta: json['textoRespuesta']?.toString(),
      estado: json['estado']?.toString() ?? 'borrador',
      archivos: archivos,
      enlaces: enlaces,
      // createEntrega/enviarEntrega escriben la fecha bajo la clave
      // "fechaEntrega" (mismo nombre que el campo de vencimiento en Tarea,
      // pero acá significa "cuándo se envió esta entrega").
      fechaEnvio: _fecha(json['fechaEntrega']),
      calificacion: calificacion != null && calificacion.valoracion >= 1 ? calificacion : null,
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
    enlaces: enlaces,
    fechaEnvio: fechaEnvio,
    calificacion: calificacion?.toEntity(),
  );
}
