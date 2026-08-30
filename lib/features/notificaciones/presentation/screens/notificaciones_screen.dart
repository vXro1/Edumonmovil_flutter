import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/notificacion.dart';
import '../providers/notificacion_providers.dart';

const _pageSize = 15;

enum _Filter { todas, noLeidas, leidas }

/// Notificaciones — BLUEPRINT.md FASE 3.10.
class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  final _items = <Notificacion>[];
  _Filter _filter = _Filter.todas;
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

  bool? get _leidoParam => switch (_filter) {
    _Filter.todas => null,
    _Filter.noLeidas => false,
    _Filter.leidas => true,
  };

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
      final result = await ref
          .read(notificacionRepositoryProvider)
          .fetchNotificaciones(page: page, limit: _pageSize, leido: _leidoParam);
      if (!mounted) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(result.items);
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
        _error = e is AppException ? e.message : 'No se pudieron cargar las notificaciones.';
      });
    }
  }

  void _onFilterChanged(_Filter filter) {
    setState(() => _filter = filter);
    _loadPage(1);
  }

  Future<void> _markAsRead(Notificacion n) async {
    if (n.leida) return;
    final index = _items.indexOf(n);
    setState(() {
      _items[index] = Notificacion(
        id: n.id,
        titulo: n.titulo,
        mensaje: n.mensaje,
        tipo: n.tipo,
        leida: true,
        createdAt: n.createdAt,
      );
    });
    try {
      await ref.read(notificacionRepositoryProvider).markAsRead(n.id);
      ref.invalidate(unreadCountProvider);
    } catch (_) {
      // No revertimos el estado local ante un fallo silencioso de red —
      // el próximo refresh de la lista corrige cualquier desincronización.
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificacionRepositoryProvider).markAllAsRead();
      ref.invalidate(unreadCountProvider);
      _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo completar la acción.')));
    }
  }

  // eliminarLeidasAntiguas real: borra las notificaciones YA LEÍDAS con más
  // de 30 días — nunca toca las no leídas, sin importar su antigüedad.
  Future<void> _limpiarAntiguas() async {
    try {
      final eliminadas = await ref.read(notificacionRepositoryProvider).deleteLeidasAntiguas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(eliminadas > 0 ? 'Se eliminaron $eliminadas notificaciones antiguas.' : 'No había notificaciones antiguas para eliminar.')),
      );
      _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo completar la acción.')));
    }
  }

  Future<void> _delete(Notificacion n) async {
    setState(() => _items.remove(n));
    try {
      await ref.read(notificacionRepositoryProvider).delete(n.id);
      if (!n.leida) ref.invalidate(unreadCountProvider);
    } catch (_) {
      _loadPage(1);
    }
  }

  ({IconData icon, Color color}) _visualsFor(NotificacionTipo tipo) {
    return switch (tipo) {
      NotificacionTipo.tarea => (icon: LucideIcons.target, color: AppColors.accent),
      NotificacionTipo.entrega => (icon: LucideIcons.fileCheck, color: AppColors.success),
      NotificacionTipo.calificacion => (icon: LucideIcons.star, color: AppColors.warning),
      NotificacionTipo.foro => (icon: LucideIcons.messageSquare, color: AppColors.secondary),
      NotificacionTipo.evento => (icon: LucideIcons.partyPopper, color: AppColors.secondary),
      NotificacionTipo.sistema => (icon: LucideIcons.info, color: AppColors.primary),
    };
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(onPressed: _markAllAsRead, child: const Text('Marcar todas')),
          PopupMenuButton<VoidCallback>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: (accion) => accion(),
            itemBuilder: (context) => [
              PopupMenuItem(value: _limpiarAntiguas, child: const Text('Limpiar leídas antiguas')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.todas, label: Text('Todas')),
                ButtonSegment(value: _Filter.noLeidas, label: Text('Sin leer')),
                ButtonSegment(value: _Filter.leidas, label: Text('Leídas')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => _onFilterChanged(s.first),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingScreenWidget();

    if (_error != null && _items.isEmpty) {
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

    if (_items.isEmpty) {
      return Center(
        child: Text('No tenés notificaciones.', style: TextStyle(color: AppColors.mutedText(context))),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(1),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        itemCount: _items.length + 1,
        separatorBuilder: (_, index) => index < _items.length - 1 ? const SizedBox(height: AppSpacing.xs) : const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (!_hasMore) return const SizedBox(height: AppSpacing.lg);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: () => _loadPage(_page + 1), child: const Text('Cargar más')),
              ),
            );
          }

          final n = _items[index];
          final visuals = _visualsFor(n.tipo);

          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.errorSurface(context.isDarkMode),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: const Icon(LucideIcons.trash2, color: AppColors.error),
            ),
            onDismissed: (_) => _delete(n),
            child: _NotificacionTile(
              notificacion: n,
              color: visuals.color,
              icon: visuals.icon,
              relativeTime: _relativeTime(n.createdAt),
              onTap: () => _markAsRead(n),
            ),
          );
        },
      ),
    );
  }
}

/// Fila de notificación con franja lateral de color por tipo — BLUEPRINT.md
/// "cada notificación debe tener un color lateral según su tipo".
class _NotificacionTile extends StatelessWidget {
  const _NotificacionTile({
    required this.notificacion,
    required this.color,
    required this.icon,
    required this.relativeTime,
    required this.onTap,
  });

  final Notificacion notificacion;
  final Color color;
  final IconData icon;
  final String relativeTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final leida = notificacion.leida;

    return Opacity(
      opacity: leida ? 0.6 : 1,
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.titulo,
                        style: TextStyle(fontWeight: leida ? FontWeight.w500 : FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notificacion.mensaje,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  relativeTime,
                  style: TextStyle(color: isDark ? AppColors.textSubtleDark : AppColors.textSubtle, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
