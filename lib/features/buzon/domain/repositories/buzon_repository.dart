import '../entities/mensaje_buzon.dart';

abstract class BuzonRepository {
  Future<List<MensajeBuzon>> fetchMensajes({int limit});

  Future<void> marcarLeido(String id);
}
