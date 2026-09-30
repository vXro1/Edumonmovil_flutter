// Recuperación de contraseña E2E (BLUEPRINT.md FASE 14 Sprint 8, caso 1:
// "Login + primer login + recuperación de contraseña" — la parte que
// test/first_login_wizard_test.dart no cubre).
//
// Flujo completo con la app real (EdumonApp + go_router real):
// Login -> "¿Olvidaste tu contraseña?" -> pedir código -> código enviado ->
// "Ingresar código" -> nueva contraseña -> éxito -> "Ir a iniciar sesión".
//
// Solo se mockea AuthRepository — nunca se golpea el backend real.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:edumon_movil/app.dart';
import 'package:edumon_movil/features/auth/domain/entities/perfil_activo.dart';
import 'package:edumon_movil/features/auth/domain/entities/user.dart';
import 'package:edumon_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:edumon_movil/features/auth/presentation/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  String? lastRecoveryCorreo;
  String? lastResetCorreo;
  String? lastResetCodigo;
  String? lastResetPassword;

  // Nunca hay sesión — _restoreSession() debe fallar para que la app
  // arranque en /login, igual que en login_flow_test.dart.
  @override
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile() async {
    throw Exception('401 sin sesión (fake)');
  }

  @override
  Future<LoginResult> login({required String telefono, required String contrasena}) async {
    throw UnimplementedError('No se usa en este flujo.');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> requestPasswordRecovery({required String correo}) async {
    lastRecoveryCorreo = correo;
  }

  @override
  Future<void> resetPassword({required String correo, required String codigo, required String nuevaContrasena}) async {
    lastResetCorreo = correo;
    lastResetCodigo = codigo;
    lastResetPassword = nuevaContrasena;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Recuperar contraseña: pedir código -> restablecer -> volver a login', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeRepo = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const EdumonApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Login -> "¿Olvidaste tu contraseña?"
    expect(find.text('Ingresar'), findsOneWidget);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    // Forgot password: pedir código.
    expect(find.text('Recuperar contraseña'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ana@example.com');
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastRecoveryCorreo, 'ana@example.com');
    expect(find.text('Código enviado'), findsOneWidget);

    // "Ingresar código" navega a /reset-password con el correo como extra.
    await tester.tap(find.text('Ingresar código'));
    await tester.pumpAndSettle();

    // Reset password: código + nueva contraseña + confirmar (en ese orden).
    expect(find.text('Nueva contraseña'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'ClaveNueva1');
    await tester.enterText(fields.at(2), 'ClaveNueva1');
    await tester.tap(find.text('Restablecer contraseña'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastResetCorreo, 'ana@example.com');
    expect(fakeRepo.lastResetCodigo, '123456');
    expect(fakeRepo.lastResetPassword, 'ClaveNueva1');
    expect(find.text('¡Contraseña actualizada!'), findsOneWidget);

    // "Ir a iniciar sesión" vuelve a /login.
    await tester.tap(find.text('Ir a iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
