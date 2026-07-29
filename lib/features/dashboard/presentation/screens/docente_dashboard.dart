import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../eventos/presentation/providers/eventos_providers.dart';
import '../../../tareas/presentation/providers/tareas_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_stats_grid.dart';

const _misCursosLimit = 20;

String _saludo() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// Dashboard Docente — BLUEPRINT.md FASE 3.2.3.
class DocenteDashboard extends ConsumerWidget {
  const DocenteDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final cursosAsync = ref.watch(misCursosProvider(_misCursosLimit));
    final retosAsync = ref.watch(tareasActivasProvider);
    final eventosHoyAsync = ref.watch(eventosHoyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(misCursosProvider(_misCursosLimit));
          ref.invalidate(tareasActivasProvider);
          ref.invalidate(eventosHoyProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('${_saludo()}, ${user?.nombre ?? ''}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Este es el resumen de tus cursos.',
              style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            DashboardStatsGrid(
              children: [
                EdumonStatCard(
                  label: 'Mis cursos',
                  icon: LucideIcons.bookOpen,
                  color: AppColors.sectionCursos,
                  value: cursosAsync.when(
                    data: (c) => '${c.length}',
                    loading: () => '—',
                    error: (_, _) => '—',
                  ),
                  onTap: () => context.push('/cursos'),
                ),
                EdumonStatCard(
                  label: 'Estudiantes',
                  icon: LucideIcons.users,
                  color: AppColors.sectionInicio,
                  value: cursosAsync.when(
                    data: (c) => '${c.fold<int>(0, (sum, curso) => sum + curso.totalParticipantes)}',
                    loading: () => '—',
                    error: (_, _) => '—',
                  ),
                  onTap: () => context.push('/cursos'),
                ),
                EdumonStatCard(
                  label: 'Retos activos',
                  icon: LucideIcons.target,
                  color: AppColors.sectionTareas,
                  value: retosAsync.when(data: (r) => '${r.length}', loading: () => '—', error: (_, _) => '—'),
                  onTap: () => context.push('/tareas'),
                ),
                EdumonStatCard(
                  label: 'Eventos hoy',
                  icon: LucideIcons.calendar,
                  color: AppColors.sectionCalendario,
                  value: eventosHoyAsync.when(data: (e) => '${e.length}', loading: () => '—', error: (_, _) => '—'),
                  onTap: () => context.push('/eventos'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: EdumonButton(
                    label: 'Crear curso',
                    size: EdumonButtonSize.sm,
                    leftIcon: LucideIcons.plus,
                    onPressed: () => context.push('/cursos/nuevo'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EdumonButton(
                    label: 'Nuevo reto',
                    size: EdumonButtonSize.sm,
                    variant: EdumonButtonVariant.secondary,
                    leftIcon: LucideIcons.target,
                    // El picker de curso para el nuevo reto ya vive en RetosScreen.
                    onPressed: () => context.push('/tareas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Mis cursos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            cursosAsync.when(
              data: (cursos) {
                if (cursos.isEmpty) {
                  return const EdumonEmptyHint(text: 'Todavía no tenés cursos. Creá el primero para empezar.');
                }
                return Column(
                  children: cursos
                      .map(
                        (curso) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EdumonCard(
                            onTap: () => context.push('/cursos/${curso.id}'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.accentLight,
                                  backgroundImage: curso.imagenUrl != null ? NetworkImage(curso.imagenUrl!) : null,
                                  child: curso.imagenUrl == null
                                      ? const Icon(LucideIcons.bookOpen, color: AppColors.accent, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(curso.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        '${curso.totalParticipantes} participantes',
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
              error: (_, _) => const EdumonEmptyHint(text: 'No se pudieron cargar tus cursos.'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Retos activos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            retosAsync.when(
              data: (retos) {
                if (retos.isEmpty) {
                  return const EdumonEmptyHint(text: 'No tenés retos activos ahora mismo.');
                }
                return Column(
                  children: retos
                      .take(5)
                      .map(
                        (reto) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EdumonCard(
                            onTap: () => context.push('/tareas/${reto.id}'),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.target, color: AppColors.sectionTareas, size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reto.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (reto.cursoNombre != null)
                                        Text(reto.cursoNombre!, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
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
              error: (_, _) => const EdumonEmptyHint(text: 'No se pudieron cargar tus retos.'),
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
