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

/// Entidad de dominio
class Foro {
  const Foro({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.categoria,
    this.estado = 'abierto',
    required this.cursoId,
    this.docenteId,
    this.docente,
    this.archivos = const [],
    this.fechaCreacion,
    this.totalMensajes = 0,
    this.publico = false,
    this.fijado = false,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final String? categoria;

  final String estado;
  final String cursoId;

  final String? docenteId;

  /// Docente creador, populado por el backend (nombre apellido fotoPerfilUrl rol).
  final ForoAutor? docente;
  final List<Archivo> archivos;
  final DateTime? fechaCreacion;
  final int totalMensajes;
  final bool publico;
  final bool fijado;

  bool get cerrado => estado == 'cerrado';
}

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
    this.likedBy = const [],
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
  final List<String> likedBy;
  final List<Archivo> archivos;
  final String? respuestaA;
  final List<MensajeForo> respuestas;
  final bool editado;
  final bool fijado;

  bool likedByUser(String? userId) => yaLeDioLike || (userId != null && likedBy.contains(userId));
}
