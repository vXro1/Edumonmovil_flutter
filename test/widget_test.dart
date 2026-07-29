import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edumon_movil/app.dart';
import 'package:edumon_movil/core/network/cookie_jar_provider.dart';

void main() {
  testWidgets('Muestra el login cuando no hay sesión activa', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // CookieJar en memoria — sin sesión guardada, y sin acceder a disco
        // (path_provider no tiene canal de plataforma real en el entorno de test).
        overrides: [cookieJarProvider.overrideWithValue(CookieJar())],
        child: const EdumonApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Texto del login rediseñado — ver login_screen.dart.
    expect(find.text('¡Bienvenido de vuelta!'), findsOneWidget);
  });
}
