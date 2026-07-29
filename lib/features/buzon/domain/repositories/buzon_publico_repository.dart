/// Envío público de contacto (landing web) — distinto del buzón interno de
/// solo-lectura ([BuzonRepository]), que ya documenta que este POST público
/// no le pertenece. Sin autenticación: cualquier visitante puede usarlo.
abstract class BuzonPublicoRepository {
  Future<void> enviarMensaje({
    required String nombre,
    required String correo,
    String? telefono,
    String? institucion,
    required String mensaje,
  });
}
