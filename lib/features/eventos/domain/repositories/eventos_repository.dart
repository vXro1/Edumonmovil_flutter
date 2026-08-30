import 'dart:typed_data';

import '../entities/evento.dart';

class ArchivoUpload {
  const ArchivoUpload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Interfaz de dominio — BLUEPRINT.md FASE 3.6 / FASE 10.7.
/// (⚠️) No vimos eventoController.js real — shapes inferidos del blueprint.
abstract class EventosRepository {
  Future<List<Evento>> fetchEventos({String? cursoId});

  Future<List<Evento>> fetchEventosHoy();

  Future<Evento> fetchEventoById(String id);

  /// createEventoValidator real: descripcion, fechaFin, hora y ubicacion son
  /// obligatorios; cursosIds debe ser un array no vacío.
  Future<Evento> createEvento({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required String ubicacion,
    required EventoCategoria categoria,
    required List<String> cursosIds,
    ArchivoUpload? adjunto,
  });

  Future<Evento> updateEvento({
    required String id,
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? hora,
    String? ubicacion,
    EventoCategoria? categoria,
    List<String>? cursosIds,
    ArchivoUpload? adjunto,
  });

  /// DELETE real: elimina el evento (a diferencia de [cancelarEvento], que
  /// solo lo marca como cancelado).
  Future<void> deleteEvento(String id);

  /// PATCH /eventos/:id/cancelar real: soft-cancel, no elimina el evento.
  Future<Evento> cancelarEvento(String id);
}
