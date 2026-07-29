import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/home/presentation/screens/web_home_screen.dart';
import '../../features/auth/presentation/screens/first_login_wizard_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/sessions_screen.dart';
import '../../features/buzon/presentation/screens/buzon_screen.dart';
import '../../features/calendario/presentation/screens/calendario_screen.dart';
import '../../features/cursos/presentation/screens/curso_form_screen.dart';
import '../../features/cursos/presentation/screens/curso_hub_screen.dart';
import '../../features/cursos/presentation/screens/cursos_screen.dart';
import '../../features/dashboard/presentation/screens/admin_home_router.dart';
import '../../features/dashboard/presentation/screens/docente_dashboard.dart';
import '../../features/dashboard/presentation/screens/padre_dashboard.dart';
import '../../features/docentes/presentation/screens/docente_form_screen.dart';
import '../../features/docentes/presentation/screens/docentes_screen.dart';
import '../../features/entregas/presentation/screens/entregas_list_screen.dart';
import '../../features/entregas/presentation/screens/mis_entregas_screen.dart';
import '../../features/entregas/presentation/screens/realizar_entrega_screen.dart';
import '../../features/eventos/presentation/screens/evento_form_screen.dart';
import '../../features/eventos/presentation/screens/eventos_screen.dart';
import '../../features/foros/presentation/screens/forum_screen.dart';
import '../../features/instituciones/presentation/screens/institucion_detail_screen.dart';
import '../../features/instituciones/presentation/screens/institucion_form_screen.dart';
import '../../features/instituciones/presentation/screens/instituciones_screen.dart';
import '../../features/instituciones/presentation/screens/mi_institucion_screen.dart';
import '../../features/notificaciones/presentation/screens/notificaciones_screen.dart';
import '../../features/perfil/presentation/screens/profile_screen.dart';
import '../../features/perfiles/presentation/screens/perfiles_screen.dart';
import '../../features/tareas/presentation/screens/retos_screen.dart';
import '../../features/tareas/presentation/screens/tarea_detail_screen.dart';
import '../../features/tareas/presentation/screens/tarea_form_screen.dart';
import '../../features/usuarios/presentation/screens/usuario_form_screen.dart';
import '../../features/usuarios/presentation/screens/usuarios_screen.dart';
import '../design_system/loading/loading_screen.dart';
import 'app_shell.dart';

/// Router — BLUEPRINT.md FASE 5.3 / FASE 4.1.
/// Replica ProtectedRoute/PublicOnlyRoute/RoleRedirect de la web vía `redirect`,
/// sin los guards muertos (RoleGuard/RequireRole/RequireAuth no se portan).

const _publicOnlyRoutes = {'/', '/login', '/forgot-password', '/reset-password'};

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);

  return GoRouter(
    // En web arranca en la home pública "/" (con botón a /login); en
    // Android/iOS no hay home pública, arranca directo en /splash como
    // siempre — ver WebHomeScreen y kIsWeb más abajo.
    initialLocation: kIsWeb ? '/' : '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) {
        // BUG REAL: antes acá solo se dejaba pasar '/' y '/splash' — si el
        // usuario tocaba "Iniciar sesión" en el Home mientras la sesión
        // todavía se estaba verificando en segundo plano (fetchProfile puede
        // tardar hasta 30-50s si el backend en Render está dormido), el
        // redirect mandaba /login de vuelta a /splash y ahí se quedaba
        // colgado — el botón "no hacía nada". Ninguna ruta pública (login,
        // recuperar contraseña) necesita esperar a que termine ese chequeo:
        // si resulta que ya había sesión, las ramas de abajo lo corrigen
        // solas apenas el estado se resuelve (refreshListenable reevalúa).
        return _publicOnlyRoutes.contains(location) ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        return _publicOnlyRoutes.contains(location) ? null : '/login';
      }

      // A partir de acá el usuario está autenticado.
      if (auth.primerInicioSesion) {
        return location == '/wizard' ? null : '/wizard';
      }

      if (location == '/splash' || location == '/wizard' || _publicOnlyRoutes.contains(location)) {
        return auth.user!.rol.homeRoute;
      }
      return null;
    },
    routes: [
      if (kIsWeb) GoRoute(path: '/', builder: (context, state) => const WebHomeScreen()),
      GoRoute(path: '/splash', builder: (context, state) => const LoadingScreenWidget()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map && extra['contact'] is String && extra['method'] is RecoveryMethod) {
            return ResetPasswordScreen(
              contact: extra['contact'] as String,
              method: extra['method'] as RecoveryMethod,
            );
          }
          // Deep-link directo sin pasar por Forgot Password: no hay contacto al que resetear.
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(path: '/wizard', builder: (context, state) => const FirstLoginWizardScreen()),
      GoRoute(path: '/sesiones', builder: (context, state) => const SessionsScreen()),
      GoRoute(path: '/notificaciones', builder: (context, state) => const NotificacionesScreen()),
      GoRoute(path: '/perfil', builder: (context, state) => const ProfileScreen()),

      // Gestión institucional (Sprint 3) — pantallas top-level con su propio
      // AppBar/back button, alcanzadas por push desde el nav del Shell.
      GoRoute(path: '/institucion', builder: (context, state) => const MiInstitucionScreen()),
      GoRoute(path: '/instituciones', builder: (context, state) => const InstitucionesScreen()),
      GoRoute(path: '/instituciones/nueva', builder: (context, state) => const InstitucionFormScreen()),
      GoRoute(
        path: '/instituciones/:id',
        builder: (context, state) => InstitucionDetailScreen(institucionId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/usuarios', builder: (context, state) => const UsuariosScreen()),
      GoRoute(path: '/usuarios/nuevo', builder: (context, state) => const UsuarioFormScreen()),
      GoRoute(
        path: '/usuarios/:id',
        builder: (context, state) => UsuarioFormScreen(userId: state.pathParameters['id']),
      ),
      GoRoute(path: '/docentes', builder: (context, state) => const DocentesScreen()),
      GoRoute(path: '/docentes/nuevo', builder: (context, state) => const DocenteFormScreen()),

      // Cursos (Sprint 4).
      GoRoute(path: '/cursos', builder: (context, state) => const CursosScreen()),
      GoRoute(path: '/cursos/nuevo', builder: (context, state) => const CursoFormScreen()),
      GoRoute(
        path: '/cursos/:id/editar',
        builder: (context, state) => CursoFormScreen(cursoId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/cursos/:id',
        builder: (context, state) => CursoHubScreen(cursoId: state.pathParameters['id']!),
      ),

      // Tareas/Retos + Entregas (Sprint 5).
      GoRoute(path: '/tareas', builder: (context, state) => const RetosScreen()),
      GoRoute(
        path: '/cursos/:cursoId/tareas/nueva',
        builder: (context, state) => TareaFormScreen(cursoId: state.pathParameters['cursoId']!),
      ),
      GoRoute(
        path: '/cursos/:cursoId/tareas/:tareaId/editar',
        builder: (context, state) => TareaFormScreen(
          cursoId: state.pathParameters['cursoId']!,
          tareaId: state.pathParameters['tareaId'],
        ),
      ),
      GoRoute(path: '/tareas/:id', builder: (context, state) => TareaDetailScreen(tareaId: state.pathParameters['id']!)),
      GoRoute(
        path: '/tareas/:id/entregas',
        builder: (context, state) => EntregasListScreen(tareaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tareas/:id/mi-entrega',
        builder: (context, state) => RealizarEntregaScreen(tareaId: state.pathParameters['id']!),
      ),

      // Foros (Sprint 6) — vista canónica, ruta singular "curso" tal cual
      // documenta BLUEPRINT.md FASE 3.8.3 (distinta del hub plural /cursos/:id).
      GoRoute(
        path: '/curso/:cursoId/foro/:foroId',
        builder: (context, state) => ForumScreen(
          cursoId: state.pathParameters['cursoId']!,
          foroId: state.pathParameters['foroId']!,
        ),
      ),

      // Calendario/Eventos (Sprint 6).
      GoRoute(path: '/calendario', builder: (context, state) => const CalendarioScreen()),
      GoRoute(path: '/eventos', builder: (context, state) => const EventosScreen()),
      GoRoute(
        path: '/eventos/nuevo',
        builder: (context, state) => EventoFormScreen(initialCursoId: state.extra as String?),
      ),
      GoRoute(
        path: '/eventos/:id/editar',
        builder: (context, state) => EventoFormScreen(eventoId: state.pathParameters['id']),
      ),

      // Familia (Sprint 7) — Cursos/Retos/Foros/Calendario reutilizan las
      // pantallas canónicas (ver comentarios en cursos_screen.dart/retos_screen.dart).
      GoRoute(path: '/familia/perfiles', builder: (context, state) => const PerfilesScreen()),
      GoRoute(path: '/familia/entregas', builder: (context, state) => const MisEntregasScreen()),

      // Buzón (Sprint 7).
      GoRoute(path: '/buzon', builder: (context, state) => const BuzonScreen()),

      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const AdminHomeRouter()),
          GoRoute(path: '/docente', builder: (context, state) => const DocenteDashboard()),
          GoRoute(path: '/padre', builder: (context, state) => const PadreDashboard()),
        ],
      ),
    ],
  );
});
