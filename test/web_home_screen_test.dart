import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edumon_movil/core/network/cookie_jar_provider.dart';
import 'package:edumon_movil/features/home/presentation/screens/web_home_screen.dart';

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
