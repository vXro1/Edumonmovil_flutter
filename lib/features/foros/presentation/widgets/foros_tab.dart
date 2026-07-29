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
import '../../domain/entities/foro.dart';
import '../providers/foros_providers.dart';
import 'create_foro_sheet.dart';

/// Tab Foros (dentro de curso) — BLUEPRINT.md FASE 3.4.8.
/// Los foros creados desde acá siempre van con publico:false.
class ForosTab extends ConsumerStatefulWidget {
  const ForosTab({super.key, required this.cursoId, required this.canManage});

  final String cursoId;
  final bool canManage;

  @override
  ConsumerState<ForosTab> createState() => _ForosTabState();
}

class _ForosTabState extends ConsumerState<ForosTab> {
  List<Foro> _items = const [];
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
      final items = await ref.read(forosRepositoryProvider).fetchForosPorCurso(widget.cursoId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los foros.';
      });
    }
  }

  Future<void> _openCreateForm() async {
    final created = await showCreateForoSheet(context, ref, widget.cursoId);
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.canManage
          ? FloatingActionButton(onPressed: _openCreateForm, child: const Icon(LucideIcons.plus))
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
          widget.canManage ? 'Todavía no hay foros. Creá el primero.' : 'Este curso no tiene foros todavía.',
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
          final foro = _items[index];
          return EdumonCard(
            onTap: () => context.push('/curso/${widget.cursoId}/foro/${foro.id}'),
            child: Row(
              children: [
                Icon(foro.cerrado ? LucideIcons.lock : LucideIcons.messageCircle, color: AppColors.sectionForos),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              foro.titulo,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (foro.cerrado)
                            Container(
                              margin: const EdgeInsets.only(left: AppSpacing.xs),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.isDarkMode ? AppColors.surface2Dark : AppColors.neutral200,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: const Text('Cerrado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      if (foro.descripcion != null && foro.descripcion!.isNotEmpty)
                        Text(
                          foro.descripcion!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${foro.totalMensajes} mensaje${foro.totalMensajes == 1 ? '' : 's'}',
                        style: TextStyle(color: AppColors.subtleText(context), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: AppColors.mutedText(context)),
              ],
            ),
          );
        },
      ),
    );
  }
}
