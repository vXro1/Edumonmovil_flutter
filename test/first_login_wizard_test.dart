import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:edumon_movil/core/design_system/avatars/edumon_avatar.dart';
import 'package:edumon_movil/core/security/role.dart';
import 'package:edumon_movil/features/auth/domain/entities/user.dart';
import 'package:edumon_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:edumon_movil/features/auth/domain/repositories/profile_repository.dart';
import 'package:edumon_movil/features/auth/presentation/providers/auth_providers.dart';
import 'package:edumon_movil/features/auth/presentation/screens/first_login_wizard_screen.dart';

/// Fakes en memoria — sin red real. Cubren el flujo completo del wizard:
/// Foto → Datos → Contraseña → Confirmación (orden pedido por el usuario y
/// donde se encontraron varios de los bugs reales de esta sesión).
class _FakeAuthRepository implements AuthRepository {
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
    return const LoginResult(user: _user, primerInicioSesion: true);
  }

  @override
  Future<User> fetchProfile() async => _user;

  @override
  Future<void> logout() async {}

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

class _FakeProfileRepository implements ProfileRepository {
  final calls = <String>[];

  @override
  Future<List<String>> fetchDefaultAvatars() async => const [
    'https://example.com/avatar1.png',
    'https://example.com/avatar2.png',
  ];

  @override
  Future<void> selectDefaultAvatar(String avatarUrl) async => calls.add('selectDefaultAvatar');

  @override
  Future<void> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
  }) async => calls.add('updateProfile');

  @override
  Future<void> changePassword({required String contrasenaActual, required String contrasenaNueva}) async =>
      calls.add('changePassword');

  @override
  Future<SessionsInfo> fetchSessionsInfo({required int page, required int limit}) async {
    return const SessionsInfo(isAdminView: false);
  }
}

void main() {
  testWidgets('Wizard: Foto -> Datos -> Contraseña -> Confirmación', (tester) async {
    await mockNetworkImagesFor(() async {
      final profileRepo = _FakeProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            profileRepositoryProvider.overrideWithValue(profileRepo),
          ],
          child: const MaterialApp(home: FirstLoginWizardScreen()),
        ),
      );
      // Resuelve _restoreSession (authRepositoryProvider) + _loadAvatars
      // (profileRepositoryProvider), ambos fakeados — sin red real de por medio.
      await tester.pumpAndSettle();

      // Paso 1: Foto.
      expect(find.text('¡Bienvenido a EDUMON!'), findsOneWidget);
      await tester.tap(find.byType(EdumonAvatar).last);
      await tester.pump();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Paso 2: Datos personales.
      expect(find.text('Tus datos'), findsOneWidget);
      final dataFields = find.byType(TextField);
      await tester.enterText(dataFields.at(0), 'Ana');
      await tester.enterText(dataFields.at(1), 'Gómez');
      await tester.enterText(dataFields.at(2), '3001234567');
      await tester.enterText(dataFields.at(3), 'ana@example.com');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(profileRepo.calls, contains('updateProfile'));

      // Paso 3: Contraseña (actual + nueva + confirmar, en ese orden).
      expect(find.text('Por último, tu contraseña'), findsOneWidget);
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(0), 'ClaveTemp1');
      await tester.enterText(passwordFields.at(1), 'ClaveNueva1');
      await tester.enterText(passwordFields.at(2), 'ClaveNueva1');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(profileRepo.calls, contains('changePassword'));

      // Paso 4: Confirmación.
      expect(find.text('¡Todo listo!'), findsOneWidget);
    });
  });
}
