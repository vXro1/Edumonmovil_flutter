import '../../../../core/security/role.dart';
import '../../../../shared/models/archivo.dart';
import '../../domain/entities/foro.dart';

class ForoAutorModel {
  const ForoAutorModel({required this.id, required this.nombre, this.apellido, this.rol, this.avatarUrl});

  final String id;
  final String nombre;
  final String? apellido;
  final UserRole? rol;
  final String? avatarUrl;

  factory ForoAutorModel.fromJson(Map<String, dynamic> json) {
    UserRole? rol;
    final rolRaw = json['rol']?.toString();
    if (rolRaw != null) {
      try {
        rol = UserRole.fromApiString(rolRaw);
      } catch (_) {
        rol = null;
      }
    }
    return ForoAutorModel(
      id: (json['id'] ?? json['_id']).toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString(),
      rol: rol,
      avatarUrl: json['fotoPerfilUrl']?.toString(),
    );
  }

  ForoAutor toEntity() => ForoAutor(id: id, nombre: nombre, apellido: apellido, rol: rol, avatarUrl: avatarUrl);
}

/// DTO — verificado contra foroController.js/Foro.js reales.
class ForoModel {
  const ForoModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.categoria,
    this.estado = 'abierto',
    required this.cursoId,
    this.docenteId,
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
  final int totalMensajes;
  final bool publico;
  final bool fijado;

  factory ForoModel.fromJson(Map<String, dynamic> json) {
    final cursoRaw = json['cursoId'];
    final cursoId = cursoRaw is Map ? (cursoRaw['id'] ?? cursoRaw['_id']).toString() : (cursoRaw ?? '').toString();

    // Foro.js real: el creador es "docenteId", no "creadorId".
    final docenteRaw = json['docenteId'];
    final docenteId = docenteRaw is Map ? (docenteRaw['id'] ?? docenteRaw['_id'])?.toString() : docenteRaw?.toString();

    return ForoModel(
      id: (json['id'] ?? json['_id']).toString(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      categoria: json['categoria']?.toString(),
      estado: json['estado']?.toString() ?? 'abierto',
      cursoId: cursoId,
      docenteId: docenteId,
      totalMensajes: json['totalMensajes'] is num
          ? (json['totalMensajes'] as num).toInt()
          : (json['totalMensajes'] == null ? 0 : int.tryParse(json['totalMensajes'].toString()) ?? 0),
      publico: json['publico'] == true,
      fijado: json['fijado'] == true,
    );
  }

  Foro toEntity() => Foro(
    id: id,
    titulo: titulo,
    descripcion: descripcion,
    categoria: categoria,
    estado: estado,
    cursoId: cursoId,
    docenteId: docenteId,
    totalMensajes: totalMensajes,
    publico: publico,
    fijado: fijado,
  );
}

/// DTO — BLUEPRINT.md FASE 9.9, (⚠️) shape inferido del blueprint.
class MensajeForoModel {
  const MensajeForoModel({
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
  final ForoAutorModel? autor;
  final String? autorId;
  final DateTime fecha;
  final int totalLikes;
  final bool yaLeDioLike;
  final List<Archivo> archivos;
  final String? respuestaA;
  final List<MensajeForoModel> respuestas;
  final bool editado;
  final bool fijado;

  factory MensajeForoModel.fromJson(Map<String, dynamic> json) {
    final autorRaw = json['autorId'] ?? json['autor'];
    ForoAutorModel? autor;
    String? autorId;
    if (autorRaw is Map) {
      autor = ForoAutorModel.fromJson(autorRaw as Map<String, dynamic>);
      autorId = autor.id;
    } else {
      autorId = autorRaw?.toString();
    }

    final foroRaw = json['foroId'];
    final foroId = foroRaw is Map ? (foroRaw['id'] ?? foroRaw['_id']).toString() : (foroRaw ?? '').toString();

    final archivosRaw = json['archivosAdjuntos'] ?? json['archivos'];
    final archivos = (archivosRaw is List ? archivosRaw : const [])
        .map((e) => Archivo.fromJson(e as Map<String, dynamic>))
        .toList();

    final respuestasRaw = json['respuestas'] as List?;
    final respuestas = (respuestasRaw ?? const [])
        .map((e) => MensajeForoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final respuestaARaw = json['respuestaA'];
    final respuestaA = respuestaARaw is Map ? (respuestaARaw['id'] ?? respuestaARaw['_id'])?.toString() : respuestaARaw?.toString();

    return MensajeForoModel(
      id: (json['id'] ?? json['_id']).toString(),
      foroId: foroId,
      contenido: json['contenido']?.toString() ?? '',
      autor: autor,
      autorId: autorId,
      fecha: DateTime.tryParse((json['fecha'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      totalLikes: json['totalLikes'] is num
          ? (json['totalLikes'] as num).toInt()
          : (json['likes'] is List ? (json['likes'] as List).length : 0),
      yaLeDioLike: json['yaLeDioLike'] == true,
      archivos: archivos,
      respuestaA: respuestaA,
      respuestas: respuestas,
      editado: json['editado'] == true,
      fijado: json['fijado'] == true,
    );
  }

  MensajeForo toEntity() => MensajeForo(
    id: id,
    foroId: foroId,
    contenido: contenido,
    autor: autor?.toEntity(),
    autorId: autorId,
    fecha: fecha,
    totalLikes: totalLikes,
    yaLeDioLike: yaLeDioLike,
    archivos: archivos,
    respuestaA: respuestaA,
    respuestas: respuestas.map((e) => e.toEntity()).toList(),
    editado: editado,
    fijado: fijado,
  );
}
