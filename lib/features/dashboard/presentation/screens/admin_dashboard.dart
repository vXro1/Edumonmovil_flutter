import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/curso_thumbnail.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../eventos/presentation/providers/eventos_providers.dart';
import '../../../notificaciones/presentation/providers/notificacion_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_stats_grid.dart';

const _cursosLimit = 10;

/// Dashboard Administrador (institución) — BLUEPRINT.md FASE 3.2.2.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institucionAsync = ref.watch(miInstitucionProvider);
    final cursosAsync = ref.watch(cursosProvider(_cursosLimit));
    final eventosHoyAsync = ref.watch(eventosHoyProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(miInstitucionProvider);
          ref.invalidate(cursosProvider(_cursosLimit));
          ref.invalidate(eventosHoyProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.school, color: AppColors.textInverse, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: institucionAsync.when(
                      data: (institucion) => Text(
                        institucion?.nombre ?? 'Tu institución',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      loading: () => const Text('Cargando…', style: TextStyle(color: AppColors.textInverse)),
                      error: (_, _) => const Text('Tu institución', style: TextStyle(color: AppColors.textInverse)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardStatsGrid(
              children: [
                EdumonStatCard(
                  label: 'Cursos activos',
                  icon: LucideIcons.bookOpen,
                  color: AppColors.sectionCursos,
                  value: cursosAsync.when(data: (c) => '${c.length}', loading: () => '—', error: (_, _) => '—'),
                  onTap: () => context.push('/cursos'),
                ),
                AsyncStatCard(
                  label: 'Docentes asignados',
                  icon: LucideIcons.userCheck,
                  color: AppColors.sectionInicio,
                  watch: (ref) => ref.watch(usersCountProvider('docente')),
                  onTap: () => context.push('/docentes'),
                ),
                EdumonStatCard(
                  label: 'Eventos hoy',
                  icon: LucideIcons.calendar,
                  color: AppColors.sectionCalendario,
                  value: eventosHoyAsync.when(data: (e) => '${e.length}', loading: () => '—', error: (_, _) => '—'),
                  onTap: () => context.push('/eventos'),
                ),
                AsyncStatCard(
                  label: 'Notificaciones',
                  icon: LucideIcons.bell,
                  color: AppColors.sectionForos,
                  watch: (ref) => ref.watch(unreadCountProvider),
                  onTap: () => context.push('/notificaciones'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: EdumonButton(
                    label: 'Nuevo docente',
                    size: EdumonButtonSize.sm,
                    leftIcon: LucideIcons.userPlus,
                    onPressed: () => context.push('/docentes/nuevo'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EdumonButton(
                    label: 'Nuevo curso',
                    size: EdumonButtonSize.sm,
                    variant: EdumonButtonVariant.accent,
                    leftIcon: LucideIcons.plus,
                    onPressed: () => context.push('/cursos/nuevo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Cursos recientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            cursosAsync.when(
              data: (cursos) {
                if (cursos.isEmpty) {
                  return const EdumonEmptyHint(text: 'Todavía no hay cursos creados en la institución.');
                }
                return Column(
                  children: cursos
                      .take(5)
                      .map(
                        (curso) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EdumonCard(
                            onTap: () => context.push('/cursos/${curso.id}'),
                            child: Row(
                              children: [
                                CursoThumbnail(
                                  imageUrl: curso.imagenUrl,
                                  radius: 20,
                                  icon: LucideIcons.bookOpen,
                                  iconColor: AppColors.accent,
                                  backgroundColor: AppColors.accentLight,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(curso.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (curso.docenteNombre != null)
                                        Text(
                                          curso.docenteNombre!,
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
              error: (_, _) => const EdumonEmptyHint(text: 'No se pudieron cargar los cursos.'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Eventos de hoy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            eventosHoyAsync.when(
              data: (eventos) {
                if (eventos.isEmpty) {
                  return const EdumonEmptyHint(text: 'No hay eventos programados para hoy.');
                }
                return Column(
                  children: eventos
                      .map(
                        (evento) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EdumonCard(
                            onTap: () => context.push('/eventos/${evento.id}/editar'),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendarDays, color: AppColors.sectionCalendario, size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        evento.hora ?? evento.categoria.label,
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
              error: (_, _) => const EdumonEmptyHint(text: 'No se pudieron cargar los eventos.'),
            ),
          ],
        ),
      ),
    );
  }
}
