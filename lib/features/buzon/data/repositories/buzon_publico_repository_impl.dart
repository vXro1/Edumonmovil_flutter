import '../../domain/repositories/buzon_publico_repository.dart';
import '../datasources/buzon_publico_remote_datasource.dart';

class BuzonPublicoRepositoryImpl implements BuzonPublicoRepository {
  const BuzonPublicoRepositoryImpl(this._remote);

  final BuzonPublicoRemoteDataSource _remote;

  @override
  Future<void> enviarMensaje({
    required String nombre,
    required String correo,
    String? telefono,
    String? institucion,
    required String mensaje,
  }) {
    return _remote.enviarMensaje(
      nombre: nombre,
      correo: correo,
      telefono: telefono,
      institucion: institucion,
      mensaje: mensaje,
    );
  }
}
