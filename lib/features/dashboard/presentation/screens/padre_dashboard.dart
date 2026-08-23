import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/curso_thumbnail.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../entregas/presentation/providers/entregas_providers.dart';
import '../../../eventos/presentation/providers/eventos_providers.dart';
import '../../../notificaciones/presentation/providers/notificacion_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_stats_grid.dart';

const _misCursosLimit = 20;

/// Dashboard Padre/Tutor — BLUEPRINT.md FASE 3.2.4.
/// A diferencia del original web (que dejaba "Notificaciones" y "Entregas
/// pendientes" como placeholders "—" ⚠️), acá las 4 stat cards muestran datos
/// reales — "Entregas pendientes" combina fetchTareas + fetchMiEntrega igual
/// que MisEntregasScreen (ver entregasPendientesCountProvider).
class PadreDashboard extends ConsumerWidget {
  const PadreDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final cursosAsync = ref.watch(misCursosProvider(_misCursosLimit));
    final eventosHoyAsync = ref.watch(eventosHoyProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(misCursosProvider(_misCursosLimit));
          ref.invalidate(eventosHoyProvider);
          ref.invalidate(entregasPendientesCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            EdumonCard(
              child: Row(
                children: [
                  const Icon(LucideIcons.heart, color: AppColors.secondary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, ${user?.nombre ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Padre/Tutor', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                      ],
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
                EdumonStatCard(
                  label: 'Eventos hoy',
                  icon: LucideIcons.calendar,
                  color: AppColors.sectionCalendario,
                  value: eventosHoyAsync.when(data: (e) => '${e.length}', loading: () => '—', error: (_, _) => '—'),
                  onTap: () => context.push('/calendario'),
                ),
                AsyncStatCard(
                  label: 'Notificaciones',
                  icon: LucideIcons.bell,
                  color: AppColors.sectionInicio,
                  watch: (ref) => ref.watch(unreadCountProvider),
                  onTap: () => context.push('/notificaciones'),
                ),
                AsyncStatCard(
                  label: 'Entregas pendientes',
                  icon: LucideIcons.clipboardList,
                  color: AppColors.sectionTareas,
                  watch: (ref) => ref.watch(entregasPendientesCountProvider),
                  onTap: () => context.push('/familia/entregas'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Cursos de mis hijos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            cursosAsync.when(
              data: (cursos) {
                if (cursos.isEmpty) {
                  return const EdumonEmptyHint(text: 'Aún no hay cursos asignados.');
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
                          // Padre: solo lectura — lleva al calendario agregado en vez
                          // del formulario de edición (docente/admin únicamente).
                          child: EdumonCard(
                            onTap: () => context.push('/calendario'),
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
