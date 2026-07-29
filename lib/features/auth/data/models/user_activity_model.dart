import '../../domain/entities/user_activity.dart';

/// DTO — mapea la fila que devuelve getUltimasSesiones real para superadmin:
/// { userId, nombre, correo, rol, estado, ultimoAcceso }.
class UserActivityModel {
  const UserActivityModel({
    required this.userId,
    required this.nombre,
    required this.rol,
    required this.estado,
    this.correo,
    this.ultimoAcceso,
  });

  final String userId;
  final String nombre;
  final String rol;
  final String estado;
  final String? correo;
  final DateTime? ultimoAcceso;

  factory UserActivityModel.fromJson(Map<String, dynamic> json) {
    return UserActivityModel(
      userId: json['userId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      rol: json['rol']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      correo: json['correo']?.toString(),
      ultimoAcceso: json['ultimoAcceso'] != null ? DateTime.tryParse(json['ultimoAcceso'].toString()) : null,
    );
  }

  UserActivity toEntity() => UserActivity(
    userId: userId,
    nombre: nombre,
    rol: rol,
    estado: estado,
    correo: correo,
    ultimoAcceso: ultimoAcceso,
  );
}
