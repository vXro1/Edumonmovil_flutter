import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/participante.dart';

class ParticipanteModel {
  const ParticipanteModel({required this.user, this.etiqueta});

  final UserModel user;
  final String? etiqueta;

  factory ParticipanteModel.fromJson(Map<String, dynamic> json) {
    // Puede venir como {usuarioId: {...}, etiqueta} (convención real del
    // backend para refs poblados: cursoId, docenteId, adminId, etc. siempre
    // llevan sufijo "Id"), como {usuario:{...}}/{user:{...}}, o como el
    // usuario directo con la etiqueta en el mismo nivel — se soportan todas.
    final usuarioRaw = json['usuarioId'] ?? json['usuario'] ?? json['user'] ?? json;
    return ParticipanteModel(
      user: UserModel.fromJson(usuarioRaw is Map ? usuarioRaw as Map<String, dynamic> : json),
      etiqueta: json['etiqueta']?.toString() ?? json['rol']?.toString(),
    );
  }

  Participante toEntity() => Participante(user: user.toEntity(), etiqueta: etiqueta);
}
