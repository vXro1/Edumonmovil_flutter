import '../../domain/entities/mensaje_buzon.dart';

/// DTO — BLUEPRINT.md FASE 9.12, (⚠️) shape inferido del blueprint.
class MensajeBuzonModel {
  const MensajeBuzonModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.mensaje,
    this.telefono,
    this.institucion,
    this.leido = false,
    required this.createdAt,
  });

  final String id;
  final String nombre;
  final String correo;
  final String mensaje;
  final String? telefono;
  final String? institucion;
  final bool leido;
  final DateTime createdAt;

  factory MensajeBuzonModel.fromJson(Map<String, dynamic> json) {
    return MensajeBuzonModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      institucion: json['institucion']?.toString(),
      leido: json['leido'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['fecha'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  MensajeBuzon toEntity() => MensajeBuzon(
    id: id,
    nombre: nombre,
    correo: correo,
    mensaje: mensaje,
    telefono: telefono,
    institucion: institucion,
    leido: leido,
    createdAt: createdAt,
  );
}
