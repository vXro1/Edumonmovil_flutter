import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tareas/domain/entities/tarea.dart';
import '../../../tareas/presentation/providers/tareas_providers.dart';

/// Tab Tareas — BLUEPRINT.md FASE 3.4.4.
class TareasTab extends ConsumerStatefulWidget {
  const TareasTab({super.key, required this.cursoId, required this.canManage});

  final String cursoId;
  final bool canManage;

  @override
  ConsumerState<TareasTab> createState() => _TareasTabState();
}

class _TareasTabState extends ConsumerState<TareasTab> {
  List<Tarea> _items = const [];
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
      final result = await ref.read(tareasRepositoryProvider).fetchTareas(cursoId: widget.cursoId, page: 1, limit: 50);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los retos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>('/cursos/${widget.cursoId}/tareas/nueva');
                if (created == true) _load();
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
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
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.canManage ? 'Todavía no hay retos. Creá el primero.' : 'Este curso no tiene retos todavía.',
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tarea = _items[index];
          return EdumonCard(
            onTap: () async {
              final changed = await context.push<bool>('/tareas/${tarea.id}');
              if (changed == true) _load();
            },
            child: Row(
              children: [
                Icon(
                  tarea.vencida ? LucideIcons.clockAlert : LucideIcons.target,
                  color: tarea.vencida ? AppColors.error : AppColors.sectionTareas,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (tarea.fechaEntrega != null)
                        Text(
                          'Entrega: ${tarea.fechaEntrega!.day}/${tarea.fechaEntrega!.month}/${tarea.fechaEntrega!.year}',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tarea.vencida
                        ? AppColors.errorSurface(context.isDarkMode)
                        : (tarea.cerrada
                              ? (context.isDarkMode ? AppColors.surface2Dark : AppColors.neutral150)
                              : AppColors.successSurface(context.isDarkMode)),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    tarea.vencida ? 'Vencida' : (tarea.cerrada ? 'Cerrada' : 'Activa'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tarea.vencida ? AppColors.error : (tarea.cerrada ? AppColors.mutedText(context) : AppColors.success),
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
