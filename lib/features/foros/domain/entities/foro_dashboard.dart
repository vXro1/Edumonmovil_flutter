import 'foro.dart';

/// GET /foros/:id/dashboard real (foroController.js: getDashboardForo) — no
/// reemplaza los endpoints ya usados (fetchForoById/fetchMensajes), solo
/// agrega una vista de analíticas con un único fetch.
class ForoDashboard {
  const ForoDashboard({
    required this.foro,
    required this.mensajesRecientes,
    required this.participantesActivos,
    required this.estadisticas,
    required this.actividad,
  });

  final Foro foro;
  final List<MensajeForo> mensajesRecientes;
  final List<ForoParticipanteActivo> participantesActivos;
  final ForoEstadisticas estadisticas;
  final List<ForoActividadDia> actividad;
}

class ForoParticipanteActivo {
  const ForoParticipanteActivo({
    required this.id,
    required this.nombre,
    this.apellido,
    this.avatarUrl,
    required this.totalMensajes,
    required this.ultimaActividad,
  });

  final String id;
  final String nombre;
  final String? apellido;
  final String? avatarUrl;
  final int totalMensajes;
  final DateTime ultimaActividad;

  String get nombreCompleto => '$nombre ${apellido ?? ''}'.trim();
}

class ForoEstadisticas {
  const ForoEstadisticas({
    this.totalMensajes = 0,
    this.totalMensajesRaiz = 0,
    this.totalRespuestas = 0,
    this.totalParticipantes = 0,
    this.totalLikes = 0,
    this.promedioRespuestasPorMensaje = 0,
  });

  final int totalMensajes;
  final int totalMensajesRaiz;
  final int totalRespuestas;
  final int totalParticipantes;
  final int totalLikes;
  final double promedioRespuestasPorMensaje;
}

/// Un día de la ventana de actividad (últimos 7 días — foroController.js
/// real: getDashboardForo).
class ForoActividadDia {
  const ForoActividadDia({required this.fecha, required this.mensajes});

  final DateTime fecha;
  final int mensajes;
}
