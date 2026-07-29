import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/instituciones_providers.dart';

/// Instituciones (superadmin) — BLUEPRINT.md FASE 3.3.1.
class InstitucionesScreen extends ConsumerStatefulWidget {
  const InstitucionesScreen({super.key});

  @override
  ConsumerState<InstitucionesScreen> createState() => _InstitucionesScreenState();
}

class _InstitucionesScreenState extends ConsumerState<InstitucionesScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _search = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final institucionesAsync = ref.watch(institucionesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Instituciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/instituciones/nueva');
          if (created == true) ref.invalidate(institucionesListProvider);
        },
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o NIT…',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),
          Expanded(
            child: institucionesAsync.when(
              data: (instituciones) {
                final filtered = _search.isEmpty
                    ? instituciones
                    : instituciones
                          .where(
                            (i) =>
                                i.nombre.toLowerCase().contains(_search) ||
                                (i.nit?.toLowerCase().contains(_search) ?? false),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No hay instituciones que coincidan.', style: TextStyle(color: AppColors.mutedText(context))),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(institucionesListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final institucion = filtered[index];
                      return EdumonCard(
                        onTap: () async {
                          final updated = await context.push<bool>('/instituciones/${institucion.id}');
                          if (updated == true) ref.invalidate(institucionesListProvider);
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(LucideIcons.school, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(institucion.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (institucion.nit != null)
                                    Text('NIT ${institucion.nit}', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                                  if (institucion.direccion != null)
                                    Text(
                                      institucion.direccion!,
                                      style: TextStyle(color: AppColors.subtleText(context), fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, color: AppColors.subtleText(context), size: 18),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingScreenWidget(),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.wifiOff, size: 40, color: AppColors.subtleText(context)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('No se pudieron cargar las instituciones.', style: TextStyle(color: AppColors.mutedText(context))),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => ref.invalidate(institucionesListProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
