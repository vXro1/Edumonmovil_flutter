import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edumon_movil/core/security/role.dart';
import 'package:edumon_movil/features/auth/domain/entities/user.dart';
import 'package:edumon_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:edumon_movil/features/auth/presentation/providers/auth_providers.dart';
import 'package:edumon_movil/features/auth/presentation/screens/login_screen.dart';

/// Fake en memoria — evita cualquier llamada de red real durante el test.
class _FakeAuthRepository implements AuthRepository {
  bool loggedIn = false;
  String? lastTelefono;

  static const _user = User(
    id: 'u1',
    nombre: 'Ana',
    apellido: 'Gómez',
    rol: UserRole.padreTutor,
    estado: 'activo',
    cedula: '123456',
    telefono: '+573001234567',
  );

  @override
  Future<LoginResult> login({required String telefono, required String contrasena}) async {
    loggedIn = true;
    lastTelefono = telefono;
    return const LoginResult(user: _user, primerInicioSesion: false);
  }

  @override
  Future<User> fetchProfile() async => _user;

  @override
  Future<void> logout() async => loggedIn = false;

  @override
  Future<void> requestPasswordRecovery({required RecoveryMethod method, required String contact}) async {}

  @override
  Future<void> resetPassword({
    required RecoveryMethod method,
    required String contact,
    required String codigo,
    required String nuevaContrasena,
  }) async {}
}

void main() {
  testWidgets('Login: valida teléfono/contraseña antes de llamar al repo', (tester) async {
    // El login rediseñado (logo grande + formas decorativas de fondo) no
    // entra en los 800x600 por defecto del test — el botón "Ingresar" queda
    // fuera del viewport y el tap() falla el hit-test. Se agranda la
    // superficie para que el layout real entre completo, como en un celular.
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeRepo = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Sin completar nada — no debe llamar al repo.
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.textContaining('teléfono válido'), findsOneWidget);
    expect(fakeRepo.loggedIn, isFalse);

    // Con datos válidos — sí debe llamar al repo. El prefijo +57 se antepone
    // recién en AuthRemoteDataSource (ver login_usecase.dart), no acá.
    await tester.enterText(find.byType(TextField).at(0), '3001234567');
    await tester.enterText(find.byType(TextField).at(1), 'Password1');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(fakeRepo.loggedIn, isTrue);
    expect(fakeRepo.lastTelefono, '3001234567');
  });
}
