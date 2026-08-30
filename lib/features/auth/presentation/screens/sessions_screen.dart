import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/user_activity.dart';
import '../providers/auth_providers.dart';

const _pageSize = 8;

/// Sesiones / actividad — GET /users/sesiones/ultimas (getUltimasSesiones real).
/// El backend NO trackea dispositivos/IP por usuario (a diferencia de lo que
/// describía originalmente el blueprint): para la mayoría de roles solo
/// devuelve la propia última conexión; solo superadmin ve la lista paginada
/// de actividad de todos los usuarios.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final _items = <UserActivity>[];
  DateTime? _ultimoAcceso;
  bool _isAdminView = false;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      if (page == 1) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });
    try {
      final result = await ref.read(profileRepositoryProvider).fetchSessionsInfo(page: page, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(result.usersActivity);
        _ultimoAcceso = result.ultimoAcceso;
        _isAdminView = result.isAdminView;
        _page = page;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e is AppException ? e.message : 'No se pudo cargar la actividad.';
      });
    }
  }

  bool _loggingOutAll = false;

  Future<void> _logoutAllSessions() async {
    final confirmed = await EdumonDialog.confirm(
      context,
      title: 'Cerrar todas las sesiones',
      message: 'Vas a cerrar tu sesión en todos los dispositivos, incluido este. Vas a tener que iniciar sesión de nuevo.',
      confirmLabel: 'Cerrar todas',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loggingOutAll = true);
    await ref.read(authControllerProvider.notifier).logoutAll();
    // El router redirige solo a /login apenas AuthState pasa a
    // unauthenticated — no hace falta navegar acá.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad de la cuenta'),
        actions: [
          IconButton(
            icon: _loggingOutAll
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.logOut),
            tooltip: 'Cerrar todas las sesiones',
            onPressed: _loggingOutAll ? null : _logoutAllSessions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingScreenWidget();

    if (_error != null && _items.isEmpty && _ultimoAcceso == null && !_isAdminView) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifiOff, size: 40, color: AppColors.subtleText(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: () => _loadPage(1), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return _isAdminView ? _activityList() : _lastAccessCard();
  }

  Widget _lastAccessCard() {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'es_CO');
    return RefreshIndicator(
      onRefresh: () => _loadPage(1),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          EdumonCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(LucideIcons.clock, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Última conexión', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        _ultimoAcceso != null ? dateFormat.format(_ultimoAcceso!) : 'Sin registro',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityList() {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'es_CO');

    return RefreshIndicator(
      onRefresh: () => _loadPage(1),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (!_hasMore) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: () => _loadPage(_page + 1), child: const Text('Cargar más')),
              ),
            );
          }

          final activity = _items[index];
          return EdumonCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    activity.nombre.isNotEmpty ? activity.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        activity.correo ?? activity.rol,
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        activity.ultimoAcceso != null ? dateFormat.format(activity.ultimoAcceso!) : 'Sin registro',
                        style: TextStyle(color: AppColors.subtleText(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: activity.estado == 'activo'
                        ? AppColors.successSurface(context.isDarkMode)
                        : AppColors.errorSurface(context.isDarkMode),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    activity.estado,
                    style: TextStyle(
                      color: activity.estado == 'activo' ? AppColors.success : AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
