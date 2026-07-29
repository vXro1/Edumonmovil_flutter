import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/notifications/notification_permission_service.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.primerInicioSesion = false,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool primerInicioSesion;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? primerInicioSesion,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      primerInicioSesion: primerInicioSesion ?? this.primerInicioSesion,
    );
  }
}

/// Controlador de sesión — BLUEPRINT.md FASE 5.7 (equivalente a AuthContext).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Future.microtask (no una llamada directa) a propósito: si algo en la
    // cadena de _restoreSession lanzara de forma síncrona antes de llegar a
    // su primer `await` real, el catch intentaría escribir `state` mientras
    // este build() todavía no terminó de retornar — Riverpod todavía no
    // marcó este provider como inicializado en ese punto, y cualquier
    // lectura/escritura de `state` ahí revienta con "Tried to read the
    // state of an uninitialized provider". Programarlo como microtask
    // garantiza que _restoreSession (y por lo tanto cualquier `state = …`
    // que dispare) corre recién en el próximo turno del event loop, después
    // de que build() ya haya retornado y el provider quede listo.
    Future.microtask(_restoreSession);
    return const AuthState();
  }

  // La sesión vive en cookies httpOnly (access_token/refresh_token), no en un
  // token que la app pueda leer de antemano — no hay forma de saber si "hay
  // sesión" sin preguntarle al backend. El RefreshInterceptor ya intenta
  // /auth/refresh una vez si el access_token vencido devuelve 401, así que si
  // esto falla es porque de verdad no hay sesión válida (o nunca hubo login).
  Future<void> _restoreSession() async {
    try {
      final user = await ref.read(authRepositoryProvider).fetchProfile();
      // BUG CONFIRMADO: antes acá no se pasaba primerInicioSesion, así que
      // copyWith() caía siempre al default de AuthState (false) — un usuario
      // que cerraba la app a mitad del wizard de primer login (antes de
      // cambiar la contraseña, el único paso que el backend marca como
      // completado) volvía a entrar y el wizard ya no se le pedía más,
      // aunque el backend siguiera con primerInicioSesion:true. getProfile
      // real sí devuelve ese campo — ahora se usa.
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        primerInicioSesion: user.primerInicioSesion,
      );
      // Fire-and-forget — no bloquea la restauración de sesión si el
      // permiso tarda o el usuario todavía no respondió el diálogo.
      unawaited(requestNotificationPermissionOnce());
    } catch (_) {
      // Chequeo silencioso al abrir la app — si nunca hubo sesión (instalación
      // nueva, sin cookies), el 401 de /auth/profile dispara el intento de
      // refresh del RefreshInterceptor, que también falla (no hay
      // refresh_token) y llama a forceLogout(), dejando el mensaje "tu sesión
      // expiró" pegado en el estado. Acá se limpia explícitamente: este
      // chequeo inicial nunca debe mostrar ese mensaje si nunca hubo sesión.
      state = state.copyWith(status: AuthStatus.unauthenticated, clearError: true);
    }
  }

  Future<void> login({required String telefono, required String contrasena}) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final result = await ref.read(loginUseCaseProvider).call(telefono: telefono, contrasena: contrasena);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        primerInicioSesion: result.primerInicioSesion,
        clearError: true,
      );
      unawaited(requestNotificationPermissionOnce());
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: _messageFor(e));
    }
  }

  /// Llamado por el Wizard de primer login al terminar el paso 3 — el
  /// router redirige automáticamente al home apenas primerInicioSesion pasa
  /// a false (mismo mecanismo que cualquier otro cambio de AuthState).
  void completeFirstLogin() {
    state = state.copyWith(primerInicioSesion: false);
  }

  /// Vuelve a pedir /auth/profile — usado tras cambiar el perfil familiar
  /// activo (perfilesSeleccionar) para reflejar lo que devuelva el backend.
  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).fetchProfile();
      state = state.copyWith(user: user);
    } catch (_) {
      // Si falla, se mantiene el usuario que ya había en memoria.
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Invocado por el RefreshInterceptor cuando /auth/refresh también falla
  /// (refresh_token vencido/inválido) — el backend ya limpió las cookies de
  /// sesión en esa respuesta, acá solo queda reflejar el estado en la UI.
  void forceLogout() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Tu sesión expiró. Inicia sesión de nuevo.',
    );
  }

  String _messageFor(Object e) {
    if (e is AppException) return e.message;
    if (e is ArgumentError) return e.message.toString();
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
