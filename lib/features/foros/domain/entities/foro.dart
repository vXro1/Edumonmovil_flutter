import '../../../../core/security/role.dart';
import '../../../../shared/models/archivo.dart';

/// Autor embebido en un mensaje de foro — versión reducida de User, igual
/// que EntregaPadre en la feature Entregas.
class ForoAutor {
  const ForoAutor({required this.id, required this.nombre, this.apellido, this.rol, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final UserRole? rol;
  final String? avatarUrl;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.8.
/// (⚠️) No vimos foroController.js real — shapes inferidos del blueprint.
class Foro {
  const Foro({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.categoria,
    this.estado = 'activo',
    required this.cursoId,
    this.creadorId,
    this.totalMensajes = 0,
    this.publico = false,
    this.fijado = false,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final String? categoria;
  final String estado; // activo|cerrado
  final String cursoId;
  final String? creadorId;
  final int totalMensajes;
  final bool publico;
  final bool fijado;

  bool get cerrado => estado == 'cerrado';
}

/// Entidad de dominio — BLUEPRINT.md FASE 9.9.
class MensajeForo {
  const MensajeForo({
    required this.id,
    required this.foroId,
    required this.contenido,
    this.autor,
    this.autorId,
    required this.fecha,
    this.totalLikes = 0,
    this.yaLeDioLike = false,
    this.archivos = const [],
    this.respuestaA,
    this.respuestas = const [],
    this.editado = false,
    this.fijado = false,
  });

  final String id;
  final String foroId;
  final String contenido;
  final ForoAutor? autor;
  final String? autorId;
  final DateTime fecha;
  final int totalLikes;
  final bool yaLeDioLike;
  final List<Archivo> archivos;
  final String? respuestaA;
  final List<MensajeForo> respuestas;
  final bool editado;
  final bool fijado;
}
