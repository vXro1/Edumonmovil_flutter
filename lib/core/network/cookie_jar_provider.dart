import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debe overridearse en main() con un PersistCookieJar ya inicializado
/// (requiere path_provider, que es async) antes de levantar el ProviderScope.
final cookieJarProvider = Provider<CookieJar>((ref) {
  throw UnimplementedError('cookieJarProvider no fue overrideado en main()');
});
