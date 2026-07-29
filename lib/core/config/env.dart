/// Configuración de entorno de la app.
///
/// El base URL se resuelve en tiempo de build vía `--dart-define=API_BASE_URL=...`.
/// Sin ese flag, apunta al backend de producción real (Render).
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-edumon.onrender.com/api',
  );
}
