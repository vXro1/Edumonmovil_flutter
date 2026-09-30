// Login E2E (BLUEPRINT.md FASE 14 Sprint 8, "Pruebas end-to-end de flujos
// críticos" — caso 1: "Login + primer login + recuperación de contraseña").
//
// A diferencia de test/login_flow_test.dart (widget test aislado sobre
// LoginScreen suelto), acá se monta la app COMPLETA (EdumonApp, con el
// go_router real) para verificar que login -> redirect -> dashboard del rol
// funciona de punta a punta, igual que lo haría un usuario real.
//
// Solo se mockea AuthRepository (nunca se golpea el backend real desde un
// test) — el resto de providers de red (cursos, eventos, notificaciones...)
// se dejan tal cual: sus pantallas ya degradan a un estado de error propio
// (ver EdumonErrorRetry) si la llamada real falla/no hay backend alcanzable,
// así que no hace falta mockear cada uno para que el árbol de widgets renderice.
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
  bool loggedIn = false;

  @override
  Future<LoginResult> login({required String telefono, required String contrasena}) async {
    loggedIn = true;
    return LoginResult(user: user, primerInicioSesion: user.primerInicioSesion);
  }

  // Sin sesión previa: _restoreSession() de AuthController debe fallar acá
  // (como un 401 real de /auth/profile) para que la app arranque en /login
  // y no salte directo al dashboard antes de que el test pueda interactuar.
  @override
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile() async {
    if (!loggedIn) throw Exception('401 sin sesión (fake)');
    return (user: user, perfilActivo: null);
  }

  @override
  Future<void> logout() async => loggedIn = false;

  @override
  Future<void> logoutAll() async => loggedIn = false;

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

  testWidgets('Login exitoso navega al dashboard del rol (padre -> /padre)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeRepo = _FakeAuthRepository(_padre);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const EdumonApp(),
      ),
    );

    // _restoreSession() corre en un microtask — dejarlo resolver (falla,
    // porque loggedIn arranca en false) antes de que el router se asiente
    // en /login.
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '3001234567');
    await tester.enterText(find.byType(TextField).at(1), 'Password1');
    await tester.tap(find.text('Ingresar'));

    // pumpAndSettle no basta solo: hay animaciones/streams (ConnectivityBanner)
    // que nunca "se asientan" del todo, así que se bombea con timeout explícito
    // en vez de esperar a que TODO quede quieto.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(fakeRepo.loggedIn, isTrue);
    // PadreDashboard saluda con "Hola, <nombre>" — ver padre_dashboard.dart.
    expect(find.textContaining('Hola, Ana'), findsOneWidget);
    expect(find.text('Padre/Tutor'), findsOneWidget);
  });
}
