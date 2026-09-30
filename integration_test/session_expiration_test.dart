// Expiración de sesión E2E (BLUEPRINT.md FASE 14 Sprint 8, caso 7:
// "Expiración de sesión (JWT+inactividad) -> logout forzado").
//
// authController.js real: cuando /auth/refresh también falla (refresh_token
// vencido), el backend ya limpió las cookies de sesión y el RefreshInterceptor
// llama a AuthController.forceLogout() (ver api_client.dart / auth_providers.dart
// / auth_controller.dart línea ~171). Ese callback vive en la capa de red
// (Dio interceptor), no en AuthRepository, así que no hay forma de disparar
// este camino exacto solo con un fake de AuthRepository — en su lugar se
// invoca forceLogout() directo sobre el controller (mismo efecto observable
// que ve un usuario real: sesión que estaba activa, de golpe vuelve a
// /login con "Tu sesión expiró").
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:edumon_movil/app.dart';
import 'package:edumon_movil/core/security/role.dart';
import 'package:edumon_movil/features/auth/domain/entities/perfil_activo.dart';
import 'package:edumon_movil/features/auth/domain/entities/user.dart';
import 'package:edumon_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:edumon_movil/features/auth/presentation/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final User user;

  // Sesión ya activa desde que arranca la app (simula reabrir la app con
  // cookies válidas) — _restoreSession() la recoge sola.
  @override
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile() async => (user: user, perfilActivo: null);

  @override
  Future<LoginResult> login({required String telefono, required String contrasena}) async {
    return LoginResult(user: user, primerInicioSesion: user.primerInicioSesion);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> requestPasswordRecovery({required String correo}) async {}

  @override
  Future<void> resetPassword({required String correo, required String codigo, required String nuevaContrasena}) async {}
}

const _padre = User(
  id: 'padre-1',
  nombre: 'Ana',
  apellido: 'Gómez',
  rol: UserRole.padreTutor,
  estado: 'activo',
  cedula: '123456',
  telefono: '+573001234567',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Sesión expirada: forceLogout() saca al usuario a /login con el aviso', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_padre))],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const EdumonApp()));

    // _restoreSession() resuelve con sesión válida -> aterriza en PadreDashboard.
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining('Hola, Ana'), findsOneWidget);

    // Simula lo que dispara el RefreshInterceptor cuando el refresh_token
    // también venció: el usuario estaba usando la app normal, sin haber
    // tocado "Cerrar sesión" él mismo.
    container.read(authControllerProvider.notifier).forceLogout();
    await tester.pumpAndSettle();

    // El router redirige (isAuthenticated pasa a false) y LoginScreen
    // muestra el aviso vía EdumonDialog al detectar el nuevo errorMessage.
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Tu sesión expiró. Inicia sesión de nuevo.'), findsOneWidget);
  });
}
