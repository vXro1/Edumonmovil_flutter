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

  // Tonos 700 en claro / 300 en oscuro: los colores de marca "puros"
  // (amarillo, verde) no alcanzaban contraste 3:1 sobre fondo blanco.
  ({IconData icon, Color color}) _visualsFor(NotificacionTipo tipo, bool isDark) {
    return switch (tipo) {
      NotificacionTipo.tarea => (icon: LucideIcons.target, color: isDark ? AppColors.purple300 : AppColors.purple700),
      NotificacionTipo.entrega => (icon: LucideIcons.fileCheck, color: isDark ? AppColors.green300 : AppColors.green700),
      NotificacionTipo.calificacion => (icon: LucideIcons.star, color: isDark ? AppColors.yellow300 : AppColors.yellow700),
      NotificacionTipo.foro => (icon: LucideIcons.messageSquare, color: isDark ? AppColors.pink300 : AppColors.pink700),
      NotificacionTipo.evento => (icon: LucideIcons.calendar, color: isDark ? AppColors.blue300 : AppColors.blue700),
      NotificacionTipo.sistema => (icon: LucideIcons.info, color: isDark ? AppColors.neutral300 : AppColors.neutral600),
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
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: 'Marcar todas como leídas',
            onPressed: _items.any((n) => !n.leida) ? _markAllAsRead : null,
          ),
          PopupMenuButton<VoidCallback>(
            icon: const Icon(LucideIcons.ellipsisVertical),
            tooltip: 'Más opciones',
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
          // el borrado NO es automático — solo pasa si el usuario toca
          // "Limpiar leídas antiguas" en el menú (ver eliminarLeidasAntiguas
          // en el backend, no hay ningún scheduler para notificaciones)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Toca una notificación para marcarla como leída. Desliza a la izquierda o usa la papelera para eliminarla.',
                style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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
      final texto = switch (_filter) {
        _Filter.todas => 'No tienes notificaciones.',
        _Filter.noLeidas => 'Estás al día: no tienes notificaciones sin leer.',
        _Filter.leidas => 'No tienes notificaciones leídas.',
      };
      return RefreshIndicator(
        onRefresh: () => _loadPage(1),
        child: ListView(
          children: [
            const SizedBox(height: 96),
            Icon(LucideIcons.bellOff, size: 48, color: AppColors.mutedText(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(texto, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText(context), fontSize: 15)),
          ],
        ),
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
          final visuals = _visualsFor(n.tipo, context.isDarkMode);

          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: AppColors.errorSurface(context.isDarkMode),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.trash2, color: AppColors.errorHover),
                  SizedBox(width: 6),
                  Text('Eliminar', style: TextStyle(color: AppColors.errorHover, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            onDismissed: (_) => _delete(n),
            child: _NotificacionTile(
              notificacion: n,
              color: visuals.color,
              icon: visuals.icon,
              relativeTime: _relativeTime(n.createdAt),
              onTap: () => _markAsRead(n),
              onDelete: () => _delete(n),
            ),
          );
        },
      ),
    );
  }
}

/// Fila de notificación — franja lateral e ícono con el color del tipo.
/// Contraste AA en claro y oscuro: fondo de tarjeta distinto del fondo de la
/// pantalla + borde visible; las no leídas se distinguen por fondo tintado,
/// punto indicador y texto en negrita (no solo por color/opacidad).
class _NotificacionTile extends StatelessWidget {
  const _NotificacionTile({
    required this.notificacion,
    required this.color,
    required this.icon,
    required this.relativeTime,
    required this.onTap,
    required this.onDelete,
  });

  final Notificacion notificacion;
  final Color color;
  final IconData icon;
  final String relativeTime;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final leida = notificacion.leida;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final baseSurface = isDark ? AppColors.surface2Dark : AppColors.surface;
    final fondo = leida ? baseSurface : Color.alphaBlend(color.withValues(alpha: isDark ? 0.14 : 0.07), baseSurface);
    final borde = leida
        ? (isDark ? AppColors.borderNormalDark : AppColors.borderNormal)
        : color.withValues(alpha: isDark ? 0.55 : 0.35);

    return Semantics(
      container: true,
      button: !leida,
      label: '${leida ? '' : 'No leída. '}${notificacion.tipo.etiqueta}. ${notificacion.titulo}. '
          '${notificacion.mensaje}. $relativeTime',
      hint: leida ? null : 'Toca dos veces para marcar como leída',
      excludeSemantics: false,
      child: Material(
        color: fondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, 0, AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.12), shape: BoxShape.circle),
                            child: Icon(icon, color: color, size: 20),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      notificacion.tipo.etiqueta.toUpperCase(),
                                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                                    ),
                                    Text(' · $relativeTime', style: TextStyle(color: textMuted, fontSize: 12)),
                                    const Spacer(),
                                    if (!leida)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.blue300 : AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  notificacion.titulo,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                    fontWeight: leida ? FontWeight.w600 : FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  notificacion.mensaje,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: leida ? textMuted : textPrimary, fontSize: 14, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.trash2, size: 18, color: textMuted),
                          tooltip: 'Eliminar notificación',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
