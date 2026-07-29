import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../buzon/presentation/providers/buzon_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_stats_grid.dart';

/// Dashboard Superadmin — BLUEPRINT.md FASE 3.2.1.
class SuperadminDashboard extends ConsumerWidget {
  const SuperadminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institucionesAsync = ref.watch(institucionesProvider);
    final buzonAsync = ref.watch(buzonRecientesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(institucionesProvider);
          ref.invalidate(buzonRecientesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.eduDark, AppColors.primary]),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Panel de super administración',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardStatsGrid(
              children: [
                EdumonStatCard(
                  label: 'Instituciones',
                  icon: LucideIcons.school,
                  color: AppColors.sectionCursos,
                  value: institucionesAsync.when(
                    data: (i) => '${i.length}',
                    loading: () => '—',
                    error: (_, _) => '—',
                  ),
                  onTap: () => context.push('/instituciones'),
                ),
                AsyncStatCard(
                  label: 'Usuarios totales',
                  icon: LucideIcons.users,
                  color: AppColors.sectionInicio,
                  watch: (ref) => ref.watch(usersCountProvider(null)),
                  onTap: () => context.push('/usuarios'),
                ),
                AsyncStatCard(
                  label: 'Administradores',
                  icon: LucideIcons.userCog,
                  color: AppColors.sectionForos,
                  watch: (ref) => ref.watch(usersCountProvider('administrador')),
                  onTap: () => context.push('/usuarios'),
                ),
                AsyncStatCard(
                  label: 'Docentes',
                  icon: LucideIcons.userCheck,
                  color: AppColors.sectionCalendario,
                  watch: (ref) => ref.watch(usersCountProvider('docente')),
                  onTap: () => context.push('/usuarios'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: EdumonButton(
                    label: 'Nueva institución',
                    size: EdumonButtonSize.sm,
                    leftIcon: LucideIcons.plus,
                    onPressed: () => context.push('/instituciones/nueva'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EdumonButton(
                    label: 'Ver usuarios',
                    size: EdumonButtonSize.sm,
                    variant: EdumonButtonVariant.outline,
                    leftIcon: LucideIcons.users,
                    onPressed: () => context.push('/usuarios'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Instituciones recientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            institucionesAsync.when(
              data: (instituciones) {
                if (instituciones.isEmpty) {
                  return const EdumonEmptyHint(text: 'Todavía no hay instituciones registradas.');
                }
                return Column(
                  children: instituciones
                      .take(5)
                      .map(
                        (institucion) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EdumonCard(
                            onTap: () => context.push('/instituciones/${institucion.id}'),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(LucideIcons.school, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(institucion.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (institucion.nit != null)
                                        Text(
                                          'NIT ${institucion.nit}',
                                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.chevronRight, color: AppColors.subtleText(context), size: 18),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const EdumonEmptyHint(text: 'No se pudieron cargar las instituciones.'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(child: Text('Buzón', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                TextButton(onPressed: () => context.push('/buzon'), child: const Text('Ver todos')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            buzonAsync.when(
              data: (mensajes) {
                if (mensajes.isEmpty) {
                  return const EdumonEmptyHint(text: 'Todavía no llegaron mensajes al buzón.');
                }
                return Column(
                  children: mensajes
                      .map(
                        (mensaje) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EdumonCard(
                            onTap: () => context.push('/buzon'),
                            child: Row(
                              children: [
                                Icon(
                                  mensaje.leido ? LucideIcons.mailOpen : LucideIcons.mail,
                                  color: mensaje.leido ? AppColors.mutedText(context) : AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mensaje.nombre,
                                        style: TextStyle(fontWeight: mensaje.leido ? FontWeight.w500 : FontWeight.w700),
                                      ),
                                      Text(
                                        mensaje.mensaje,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const EdumonEmptyHint(text: 'No se pudieron cargar los mensajes del buzón.'),
            ),
          ],
        ),
      ),
    );
  }
}
