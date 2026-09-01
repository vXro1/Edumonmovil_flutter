import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notificaciones/presentation/providers/notificacion_providers.dart';
import '../design_system/avatars/edumon_avatar.dart';
import '../design_system/decor/edumon_logo_mark.dart';
import '../security/role.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive.dart';

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route, this.push = true});
  final IconData icon;
  final String label;
  final String route;

  /// true = pantalla top-level con su propio AppBar (se navega con push,
  /// como Notificaciones/Perfil). false = destino real del ShellRoute (Inicio),
  /// se navega con go para no apilar pantallas dentro del propio tab.
  final bool push;
}

// Cada feature nueva agrega su propio item acá cuando su pantalla esté
// construida — no antes, para no navegar a rutas inexistentes. Notificaciones
// no está en la lista porque ya es accesible desde la campana del AppBar.
// Permisos visuales del navbar por rol (decisión de producto explícita):
// - superadmin: solo gestiona instituciones/usuarios a nivel plataforma — NO
//   tiene Cursos, Calendario ni Eventos (eso es contenido de una institución
//   puntual, y él no pertenece a ninguna).
// - administrador: gestiona SU institución — si tiene Cursos/Calendario/Eventos,
//   pero solo "Mi institución" (la propia), nunca el listado global de todas
//   ("Instituciones" es exclusivo de superadmin).
List<_NavItem> _navItemsFor(UserRole rol) {
  return [
    _NavItem(icon: LucideIcons.house, label: 'Inicio', route: rol.homeRoute, push: false),
    if (rol == UserRole.superAdmin)
      const _NavItem(icon: LucideIcons.school, label: 'Instituciones', route: '/instituciones'),
    if (rol == UserRole.administrador)
      const _NavItem(icon: LucideIcons.school, label: 'Mi institución', route: '/institucion'),
    if (rol == UserRole.superAdmin || rol == UserRole.administrador)
      const _NavItem(icon: LucideIcons.users, label: 'Usuarios', route: '/usuarios'),
    if (rol == UserRole.administrador)
      const _NavItem(icon: LucideIcons.userCheck, label: 'Docentes', route: '/docentes'),
    if (rol == UserRole.administrador || rol == UserRole.docente || rol == UserRole.padreTutor)
      const _NavItem(icon: LucideIcons.bookOpen, label: 'Cursos', route: '/cursos'),
    if (rol == UserRole.docente || rol == UserRole.padreTutor)
      const _NavItem(icon: LucideIcons.target, label: 'Retos', route: '/tareas'),
    if (rol == UserRole.padreTutor)
      const _NavItem(icon: LucideIcons.fileCheck, label: 'Entregas', route: '/familia/entregas'),
    if (rol != UserRole.superAdmin)
      const _NavItem(icon: LucideIcons.calendarDays, label: 'Calendario', route: '/calendario'),
    if (rol == UserRole.administrador || rol == UserRole.docente)
      const _NavItem(icon: LucideIcons.partyPopper, label: 'Eventos', route: '/eventos'),
    if (rol == UserRole.padreTutor)
      const _NavItem(icon: LucideIcons.users, label: 'Perfiles', route: '/familia/perfiles'),
    // "Buzón" se sacó del navbar por decisión de producto — quedaba
    // redundante con Notificaciones (ya accesible para todos los roles,
    // incluido superadmin, desde la campana del AppBar). La pantalla/ruta
    // /buzon y el endpoint real (superadmin-only, ver buzonRoutes.js) siguen
    // intactos por si se decide reincorporarlo más adelante.
    // Configuración (Mi perfil) — antes solo accesible desde el menú del
    // avatar en el AppBar, ahora también como ítem propio del navbar para
    // los 4 roles (BLUEPRINT.md FASE 3.11 / tabla 4.2: universal).
    const _NavItem(icon: LucideIcons.settings, label: 'Configuración', route: '/perfil'),
  ];
}

/// Shell responsivo — BLUEPRINT.md FASE 7 / FASE 5.6.
/// compact: Drawer. medium: NavigationRail solo-íconos. expanded: NavigationRail extendido.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return child;

    final breakpoint = Breakpoint.of(context);
    final navItems = _navItemsFor(user.rol);
    var selectedIndex = navItems.indexWhere((i) => i.route == location);
    if (selectedIndex == -1) selectedIndex = 0;

    final isDark = context.isDarkMode;

    if (breakpoint.isCompact) {
      return Scaffold(
        appBar: _AppShellAppBar(showMenuButton: true),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: EdumonLogoMark(iconSize: 48, wordmarkWidth: 110)),
                ),
                for (var i = 0; i < navItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      leading: Icon(
                        navItems[i].icon,
                        color: i == selectedIndex ? AppColors.primary : AppColors.subtleText(context),
                      ),
                      title: Text(
                        navItems[i].label,
                        style: TextStyle(
                          color: i == selectedIndex
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                          fontWeight: i == selectedIndex ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: i == selectedIndex,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (navItems[i].push) {
                          context.push(navItems[i].route);
                        } else {
                          context.go(navItems[i].route);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        body: child,
      );
    }

    return Scaffold(
      appBar: _AppShellAppBar(showMenuButton: false),
      body: Row(
        children: [
          NavigationRailTheme(
            data: NavigationRailThemeData(
              backgroundColor: isDark ? AppColors.sidebarBg : AppColors.surface,
              indicatorColor: AppColors.primary,
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              selectedIconTheme: const IconThemeData(color: AppColors.textInverse),
              unselectedIconTheme: IconThemeData(color: isDark ? AppColors.sidebarText : AppColors.textSubtle),
              selectedLabelTextStyle: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle: TextStyle(color: isDark ? AppColors.sidebarText : AppColors.textMuted),
            ),
            child: NavigationRail(
              extended: breakpoint.isExpanded,
              minExtendedWidth: 280,
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) =>
                  navItems[i].push ? context.push(navItems[i].route) : context.go(navItems[i].route),
              labelType: breakpoint.isExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              destinations: [
                for (final item in navItems)
                  NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AppShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _AppShellAppBar({required this.showMenuButton});

  final bool showMenuButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final user = ref.watch(authControllerProvider).user;

    return AppBar(
      title: const Text('EDUMON'),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.search),
          tooltip: 'Buscar',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La búsqueda global llega en un sprint próximo.')),
            );
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.bell),
              tooltip: 'Notificaciones',
              onPressed: () => context.push('/notificaciones'),
            ),
            if (unreadCount.value != null && unreadCount.value! > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text(
                    unreadCount.value! > 9 ? '9+' : '${unreadCount.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textInverse, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<String>(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          icon: EdumonAvatar(
            radius: 16,
            imageUrl: user?.avatarUrl,
            fallbackText: (user?.nombre.isNotEmpty == true ? user!.nombre[0] : '?').toUpperCase(),
          ),
          onSelected: (value) {
            switch (value) {
              case 'perfil':
                context.push('/perfil');
              case 'logout':
                ref.read(authControllerProvider.notifier).logout();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'perfil', child: Text('Mi perfil')),
            PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
          ],
        ),
      ],
    );
  }
}
