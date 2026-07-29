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

  Future<Evento> createEvento({
    required String titulo,
    String? descripcion,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? hora,
    String? ubicacion,
    required EventoCategoria categoria,
    List<String> cursosIds = const [],
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

  Future<void> deleteEvento(String id);
}
