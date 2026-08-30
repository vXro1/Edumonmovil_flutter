import '../../domain/entities/foro_dashboard.dart';
import 'foro_model.dart';

class ForoDashboardModel {
  const ForoDashboardModel({
    required this.foro,
    required this.mensajesRecientes,
    required this.participantesActivos,
    required this.estadisticas,
    required this.actividad,
  });

  final ForoModel foro;
  final List<MensajeForoModel> mensajesRecientes;
  final List<ForoParticipanteActivo> participantesActivos;
  final ForoEstadisticas estadisticas;
  final List<ForoActividadDia> actividad;

  factory ForoDashboardModel.fromJson(Map<String, dynamic> json) {
    final mensajesRaw = json['mensajesRecientes'] as List?;
    final participantesRaw = json['participantesActivos'] as List?;
    final actividadRaw = json['actividad'] as List?;
    final estadisticasRaw = json['estadisticas'] as Map<String, dynamic>? ?? const {};

    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    double asDouble(dynamic v) => v is num ? v.toDouble() : 0;

    return ForoDashboardModel(
      foro: ForoModel.fromJson(json['foro'] as Map<String, dynamic>),
      mensajesRecientes: (mensajesRaw ?? const [])
          .map((e) => MensajeForoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      participantesActivos: (participantesRaw ?? const []).map((e) {
        final map = e as Map<String, dynamic>;
        return ForoParticipanteActivo(
          id: (map['id'] ?? map['_id']).toString(),
          nombre: map['nombre']?.toString() ?? '',
          apellido: map['apellido']?.toString(),
          avatarUrl: map['fotoPerfilUrl']?.toString(),
          totalMensajes: asInt(map['totalMensajes']),
          ultimaActividad: DateTime.tryParse((map['ultimaActividad'] ?? '').toString()) ?? DateTime.now(),
        );
      }).toList(),
      estadisticas: ForoEstadisticas(
        totalMensajes: asInt(estadisticasRaw['totalMensajes']),
        totalMensajesRaiz: asInt(estadisticasRaw['totalMensajesRaiz']),
        totalRespuestas: asInt(estadisticasRaw['totalRespuestas']),
        totalParticipantes: asInt(estadisticasRaw['totalParticipantes']),
        totalLikes: asInt(estadisticasRaw['totalLikes']),
        promedioRespuestasPorMensaje: asDouble(estadisticasRaw['promedioRespuestasPorMensaje']),
      ),
      actividad: (actividadRaw ?? const []).map((e) {
        final map = e as Map<String, dynamic>;
        return ForoActividadDia(
          fecha: DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now(),
          mensajes: asInt(map['mensajes']),
        );
      }).toList(),
    );
  }

  ForoDashboard toEntity() => ForoDashboard(
    foro: foro.toEntity(),
    mensajesRecientes: mensajesRecientes.map((e) => e.toEntity()).toList(),
    participantesActivos: participantesActivos,
    estadisticas: estadisticas,
    actividad: actividad,
  );
}
