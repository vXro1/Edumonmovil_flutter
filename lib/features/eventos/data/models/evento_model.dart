import '../../../../shared/models/archivo.dart';
import '../../domain/entities/evento.dart';

/// DTO — BLUEPRINT.md FASE 9.10, (⚠️) shape inferido del blueprint.
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

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    final cursosRaw = json['cursosIds'] as List?;
    final cursosIds = (cursosRaw ?? const [])
        .map((e) => e is Map ? (e['id'] ?? e['_id']).toString() : e.toString())
        .toList();

    final adjuntoRaw = json['adjunto'];

    return EventoModel(
      id: (json['id'] ?? json['_id']).toString(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      fechaInicio: DateTime.tryParse((json['fechaInicio'] ?? '').toString()) ?? DateTime.now(),
      fechaFin: json['fechaFin'] != null ? DateTime.tryParse(json['fechaFin'].toString()) : null,
      hora: json['hora']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      categoria: EventoCategoria.fromApiString(json['categoria']?.toString()),
      cursosIds: cursosIds,
      adjunto: adjuntoRaw is Map ? Archivo.fromJson(adjuntoRaw as Map<String, dynamic>) : null,
      estado: json['estado']?.toString() ?? 'programado',
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
  );
}
