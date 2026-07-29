import '../../domain/entities/institucion_resumen.dart';

class InstitucionResumenModel {
  const InstitucionResumenModel({required this.id, required this.nombre, this.nit, this.direccion});

  final String id;
  final String nombre;
  final String? nit;
  final String? direccion;

  factory InstitucionResumenModel.fromJson(Map<String, dynamic> json) {
    return InstitucionResumenModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      nit: json['nit']?.toString(),
      direccion: json['direccion']?.toString(),
    );
  }

  InstitucionResumen toEntity() => InstitucionResumen(id: id, nombre: nombre, nit: nit, direccion: direccion);
}
