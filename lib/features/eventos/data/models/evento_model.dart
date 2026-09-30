import '../../../../core/config/env.dart';
import '../../../../shared/models/archivo.dart';
import '../../domain/entities/evento.dart';

/// DTO — verificado contra Evento.js/eventoController.js reales.
class EventoModel {
  const EventoModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    this.hora,
    this.ubicacion,
    this.categoria = EventoCategoria.institucional,
    this.cursosIds = const [],
    this.adjunto,
    this.estado = 'programado',
    this.cursosNombres = const [],
    this.docenteNombre,
    this.imagenPortadaUrl,
    this.fechaCreacion,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? hora;
  final String? ubicacion;
  final EventoCategoria categoria;
  final List<String> cursosIds;
  final Archivo? adjunto;
  final String estado;
  final List<String> cursosNombres;
  final String? docenteNombre;
  final String? imagenPortadaUrl;
  final DateTime? fechaCreacion;

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    final cursosRaw = json['cursosIds'] as List?;
    final cursosIds = (cursosRaw ?? const [])
        .map((e) => e is Map ? (e['id'] ?? e['_id']).toString() : e.toString())
        .toList();

    final cursosNombres = (cursosRaw ?? const [])
        .whereType<Map>()
        .map((e) => e['nombre']?.toString())
        .whereType<String>()
        .toList();

    // BUG REAL corregido: Evento.js guarda el archivo en "adjuntos" (objeto
    // {url, publicId, nombre}, con url null si no hay) — se leía "adjunto",
    // que no existe, así que el adjunto de un evento nunca se mostraba.
    final adjuntoRaw = json['adjuntos'] ?? json['adjunto'];
    final adjunto = adjuntoRaw is Map && adjuntoRaw['url'] != null
        ? Archivo.fromJson({...adjuntoRaw.cast<String, dynamic>(), 'nombre': adjuntoRaw['nombre'] ?? 'Adjunto del evento'})
        : null;

    final portadaRaw = json['imagenPortada'];
    final portadaUrl = portadaRaw is Map ? Env.resolveUrl(portadaRaw['url']?.toString()) : null;

    final docenteRaw = json['docenteId'];
    String? docenteNombre;
    if (docenteRaw is Map) {
      docenteNombre = '${docenteRaw['nombre'] ?? ''} ${docenteRaw['apellido'] ?? ''}'.trim();
      if (docenteNombre.isEmpty) docenteNombre = null;
    }

    DateTime? fecha(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

    return EventoModel(
      id: (json['id'] ?? json['_id']).toString(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      fechaInicio: fecha(json['fechaInicio']) ?? DateTime.now(),
      fechaFin: fecha(json['fechaFin']),
      hora: json['hora']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      categoria: EventoCategoria.fromApiString(json['categoria']?.toString()),
      cursosIds: cursosIds,
      adjunto: adjunto,
      estado: json['estado']?.toString() ?? 'programado',
      cursosNombres: cursosNombres,
      docenteNombre: docenteNombre,
      imagenPortadaUrl: portadaUrl != null && portadaUrl.isNotEmpty ? portadaUrl : null,
      fechaCreacion: fecha(json['fechaCreacion'] ?? json['createdAt']),
    );
  }

  Evento toEntity() => Evento(
    id: id,
    titulo: titulo,
    descripcion: descripcion,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    hora: hora,
    ubicacion: ubicacion,
    categoria: categoria,
    cursosIds: cursosIds,
    adjunto: adjunto,
    estado: estado,
    cursosNombres: cursosNombres,
    docenteNombre: docenteNombre,
    imagenPortadaUrl: imagenPortadaUrl,
    fechaCreacion: fechaCreacion,
  );
}
