import '../../domain/entities/mensaje_buzon.dart';
import '../../domain/repositories/buzon_repository.dart';
import '../datasources/buzon_remote_datasource.dart';

class BuzonRepositoryImpl implements BuzonRepository {
  const BuzonRepositoryImpl(this._remote);

  final BuzonRemoteDataSource _remote;

  @override
  Future<List<MensajeBuzon>> fetchMensajes({int limit = 50}) async {
    final result = await _remote.fetchMensajes(limit: limit);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> marcarLeido(String id) => _remote.marcarLeido(id);
}
