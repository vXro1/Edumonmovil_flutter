import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edumon_movil/core/network/cookie_jar_provider.dart';
import 'package:edumon_movil/features/home/presentation/screens/web_home_screen.dart';

/// Regresión de layout — cubre bugs reales encontrados en QA:
/// 1. Una Row con CrossAxisAlignment.stretch + Expanded dentro de un Column
///    sin alto acotado (el SingleChildScrollView de la página) le pasaba
///    altura infinita a sus hijos (landing_pilares_section.dart).
/// 2. Un badge con Row(mainAxisSize: min) + Text sin envolver se salía del
///    ancho disponible en pantallas angostas (landing_hero.dart).
/// 3. IntrinsicHeight (el primer intento de arreglar #1 manteniendo tarjetas
///    de igual alto) medía el alto con un ancho distinto al ancho final de
///    cada tarjeta ya angostada por Expanded, y volvía a overflowear en el
///    breakpoint "medium" (3 tarjetas, ni compacto ni ancho de sobra).
/// Todos son asserts de debug — invisibles en release/profile, donde el
/// layout queda corrupto en silencio en vez de tirar el error. flutter test
/// corre con los asserts activos, así que detecta esto igual que
/// `flutter run` en modo debug, sin necesitar levantar un navegador. Se
/// cubren varios anchos representativos (BLUEPRINT: "verse perfectamente en
/// ultrawide, escritorio, laptops, tablets horizontales/verticales,
/// móviles, pantallas pequeñas") porque el bug #3 solo aparecía en un rango
/// intermedio, no en los extremos.
Future<void> _pumpAndCheck(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [cookieJarProvider.overrideWithValue(CookieJar())],
      child: const MaterialApp(home: WebHomeScreen()),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(tester.takeException(), isNull);
}

const _widths = <String, double>{
  '320px': 320,
  '360px': 360,
  '375px': 375,
  '390px': 390,
  '412px': 412,
  '480px': 480,
  '600px': 600,
  '768px': 768,
  '1024px': 1024,
  '1280px': 1280,
  '1440px': 1440,
  '1920px': 1920,
  'ultrawide 2560px': 2560,
};

void main() {
  for (final entry in _widths.entries) {
    testWidgets('Home web: sin excepciones de RenderBox en ${entry.key} (${entry.value}px)', (tester) async {
      await _pumpAndCheck(tester, Size(entry.value, 2600));
    });
  }
}
