// Participar en foro E2E (BLUEPRINT.md FASE 14 Sprint 8, caso 4:
// "Participar en foro (mensaje/respuesta/like)").
//
// ForumScreen se monta sola (no hace falta el router completo: no navega a
// otras rutas en este flujo) con un ForosRepository fake que mantiene
// estado en memoria — así enviarMensaje/toggleLike se reflejan de verdad en
// el siguiente fetchMensajes, igual que haría el backend real.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:edumon_movil/core/security/role.dart';
import 'package:edumon_movil/features/auth/domain/entities/perfil_activo.dart';
import 'package:edumon_movil/features/auth/domain/entities/user.dart';
import 'package:edumon_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:edumon_movil/features/auth/presentation/providers/auth_providers.dart';
import 'package:edumon_movil/features/foros/domain/entities/foro.dart';
import 'package:edumon_movil/features/foros/domain/entities/foro_dashboard.dart';
import 'package:edumon_movil/features/foros/domain/repositories/foros_repository.dart';
import 'package:edumon_movil/features/foros/presentation/providers/foros_providers.dart';
import 'package:edumon_movil/features/foros/presentation/screens/forum_screen.dart';

const _padre = User(
  id: 'padre-1',
  nombre: 'Ana',
  apellido: 'Gómez',
  rol: UserRole.padreTutor,
  estado: 'activo',
  cedula: '123456',
  telefono: '+573001234567',
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<({User user, PerfilActivo? perfilActivo})> fetchProfile() async => (user: _padre, perfilActivo: null);

  @override
  Future<LoginResult> login({required String telefono, required String contrasena}) async =>
      const LoginResult(user: _padre, primerInicioSesion: false);

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> requestPasswordRecovery({required String correo}) async {}

  @override
  Future<void> resetPassword({required String correo, required String codigo, required String nuevaContrasena}) async {}
}

class _FakeForosRepository implements ForosRepository {
  final _mensajes = <MensajeForo>[
    MensajeForo(
      id: 'm1',
      foroId: 'f1',
      contenido: 'Bienvenidos al foro del curso',
      autor: const ForoAutor(id: 'docente-1', nombre: 'Carlos', apellido: 'Ruiz', rol: UserRole.docente),
      autorId: 'docente-1',
      fecha: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<List<Foro>> fetchForosPorCurso(String cursoId) async => [
    const Foro(id: 'f1', titulo: 'Foro general', cursoId: 'curso-1', docenteId: 'docente-1'),
  ];

  @override
  Future<Foro> fetchForoById(String id) async =>
      const Foro(id: 'f1', titulo: 'Foro general', cursoId: 'curso-1', docenteId: 'docente-1');

  @override
  Future<List<MensajeForo>> fetchMensajes(String foroId) async => List.unmodifiable(_mensajes);

  @override
  Future<void> toggleLike(String mensajeId) async {
    final i = _mensajes.indexWhere((m) => m.id == mensajeId);
    if (i == -1) return;
    final m = _mensajes[i];
    _mensajes[i] = MensajeForo(
      id: m.id,
      foroId: m.foroId,
      contenido: m.contenido,
      autor: m.autor,
      autorId: m.autorId,
      fecha: m.fecha,
      totalLikes: m.yaLeDioLike ? m.totalLikes - 1 : m.totalLikes + 1,
      yaLeDioLike: !m.yaLeDioLike,
      respuestas: m.respuestas,
    );
  }

  @override
  Future<MensajeForo> enviarMensaje({
    required String foroId,
    required String contenido,
    String? respuestaA,
    List<ArchivoUpload>? archivos,
  }) async {
    final nuevo = MensajeForo(
      id: 'm-nuevo',
      foroId: foroId,
      contenido: contenido,
      autor: const ForoAutor(id: 'padre-1', nombre: 'Ana', apellido: 'Gómez', rol: UserRole.padreTutor),
      autorId: 'padre-1',
      fecha: DateTime(2026, 1, 2),
      respuestaA: respuestaA,
    );
    if (respuestaA != null) {
      final i = _mensajes.indexWhere((m) => m.id == respuestaA);
      if (i != -1) {
        final padre = _mensajes[i];
        _mensajes[i] = MensajeForo(
          id: padre.id,
          foroId: padre.foroId,
          contenido: padre.contenido,
          autor: padre.autor,
          autorId: padre.autorId,
          fecha: padre.fecha,
          totalLikes: padre.totalLikes,
          yaLeDioLike: padre.yaLeDioLike,
          respuestas: [...padre.respuestas, nuevo],
        );
      }
    } else {
      _mensajes.add(nuevo);
    }
    return nuevo;
  }

  @override
  Future<ForoDashboard> fetchDashboard(String foroId) async => throw UnimplementedError();

  @override
  Future<Foro> createForo({
    required String titulo,
    required String descripcion,
    required String cursoId,
    bool publico = false,
    List<ArchivoUpload>? archivos,
  }) async => throw UnimplementedError();

  @override
  Future<Foro> updateForo({required String id, String? titulo, String? descripcion, bool? publico}) async =>
      throw UnimplementedError();

  @override
  Future<void> toggleEstadoForo({required String id, required bool cerrado}) async => throw UnimplementedError();

  @override
  Future<void> deleteForo(String id) async => throw UnimplementedError();

  @override
  Future<void> editarMensaje({required String id, required String contenido}) async => throw UnimplementedError();

  @override
  Future<void> deleteMensaje(String id) async => throw UnimplementedError();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Foro: dar like, responder a un mensaje de docente y enviarlo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeForos = _FakeForosRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          forosRepositoryProvider.overrideWithValue(fakeForos),
        ],
        child: const MaterialApp(home: ForumScreen(cursoId: 'curso-1', foroId: 'f1')),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Bienvenidos al foro del curso'), findsOneWidget);

    // Like: el corazón arranca sin "like propio" del padre.
    await tester.tap(find.byIcon(LucideIcons.heart));
    await tester.pumpAndSettle();
    expect(fakeForos._mensajes.first.yaLeDioLike, isTrue);
    expect(fakeForos._mensajes.first.totalLikes, 1);
    expect(find.text('1'), findsOneWidget);

    // Responder: un padre SÍ puede responder a un mensaje de un docente.
    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Respondiendo a Carlos'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Gracias, profe!');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();

    expect(find.text('Gracias, profe!'), findsOneWidget);
    expect(fakeForos._mensajes.first.respuestas, hasLength(1));
    expect(fakeForos._mensajes.first.respuestas.first.contenido, 'Gracias, profe!');
  });
}
