import '../entities/mensaje_buzon.dart';

/// Interfaz de dominio — BLUEPRINT.md FASE 3.9 / FASE 10.8. Solo lectura +
/// marcar leído: el POST público de contacto es de la landing web, no de
/// esta app. (⚠️) No vimos buzonController.js real.
abstract class BuzonRepository {
  Future<List<MensajeBuzon>> fetchMensajes({int limit});

  Future<void> marcarLeido(String id);
}
