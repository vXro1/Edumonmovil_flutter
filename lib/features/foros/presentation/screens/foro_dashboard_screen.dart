import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/foro_dashboard.dart';
import '../providers/foros_providers.dart';

/// Dashboard del foro — GET /foros/:id/dashboard real. No reemplaza la vista
/// de mensajes (ForumScreen), es una vista de analíticas aparte con un solo
/// fetch: mensajes recientes, participantes activos, estadísticas y
/// actividad de los últimos 7 días.
class ForoDashboardScreen extends ConsumerStatefulWidget {
  const ForoDashboardScreen({super.key, required this.foroId});

  final String foroId;

  @override
  ConsumerState<ForoDashboardScreen> createState() => _ForoDashboardScreenState();
}

class _ForoDashboardScreenState extends ConsumerState<ForoDashboardScreen> {
  ForoDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await ref.read(forosRepositoryProvider).fetchDashboard(widget.foroId);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar el dashboard.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_dashboard != null ? '${_dashboard!.foro.titulo} · Estadísticas' : 'Estadísticas del foro')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingScreenWidget();

    if (_error != null) {
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
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final dashboard = _dashboard!;
    final stats = dashboard.estadisticas;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
            children: [
              _StatTile(label: 'Mensajes', value: '${stats.totalMensajes}', icon: LucideIcons.messageSquare, color: AppColors.accent),
              _StatTile(label: 'Respuestas', value: '${stats.totalRespuestas}', icon: LucideIcons.reply, color: AppColors.secondary),
              _StatTile(label: 'Participantes', value: '${stats.totalParticipantes}', icon: LucideIcons.users, color: AppColors.primary),
              _StatTile(label: 'Likes', value: '${stats.totalLikes}', icon: LucideIcons.heart, color: AppColors.error),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Actividad — últimos 7 días', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.mutedText(context))),
          const SizedBox(height: AppSpacing.sm),
          EdumonCard(child: _ActivityChart(actividad: dashboard.actividad)),
          const SizedBox(height: AppSpacing.md),
          Text('Participantes más activos', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.mutedText(context))),
          const SizedBox(height: AppSpacing.sm),
          if (dashboard.participantesActivos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Todavía no hay actividad.', style: TextStyle(color: AppColors.mutedText(context))),
            )
          else
            ...dashboard.participantesActivos.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: EdumonCard(
                  child: Row(
                    children: [
                      EdumonAvatar(
                        radius: 18,
                        imageUrl: p.avatarUrl,
                        fallbackText: p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(p.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('${p.totalMensajes} mensajes', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return EdumonCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Text(label, style: TextStyle(color: AppColors.mutedText(context), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barras simples dibujadas a mano (sin librería de charts nueva) — la app
/// no tenía ninguna dependencia de gráficos y esta es la única vista que
/// necesita una, así que no se justifica agregarla solo para 7 barras.
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.actividad});

  final List<ForoActividadDia> actividad;

  @override
  Widget build(BuildContext context) {
    if (actividad.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('Sin datos de actividad.', style: TextStyle(color: AppColors.mutedText(context))),
      );
    }
    final maxValue = actividad.map((d) => d.mensajes).fold(0, (a, b) => a > b ? a : b);
    const diasCorto = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final dia in actividad)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${dia.mensajes}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                    const SizedBox(height: 4),
                    Container(
                      height: maxValue > 0 ? 8 + (dia.mensajes / maxValue) * 72 : 8,
                      decoration: BoxDecoration(
                        color: dia.mensajes > 0 ? AppColors.sectionForos : AppColors.neutral150,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(diasCorto[dia.fecha.weekday - 1], style: TextStyle(fontSize: 11, color: AppColors.subtleText(context))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
