import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_stats_grid.dart';

const _cursosLimit = 50;

/// Mi Institución (admin, solo lectura) — BLUEPRINT.md FASE 3.3.2.
/// (⚠️) "Estudiantes" queda como placeholder porque no hay endpoint que
/// cuente estudiantes por institución en el backend actual — el resto de
/// los stats sí son reales (a diferencia del hardcode "1"/"—" que tenía la
/// web original para Administradores y Docentes).
class MiInstitucionScreen extends ConsumerWidget {
  const MiInstitucionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institucionAsync = ref.watch(miInstitucionProvider);
    final user = ref.watch(authControllerProvider).user;
    final cursosAsync = ref.watch(cursosProvider(_cursosLimit));

    return Scaffold(
      appBar: AppBar(title: const Text('Mi institución')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(miInstitucionProvider);
          ref.invalidate(cursosProvider(_cursosLimit));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            DashboardStatsGrid(
              children: [
                EdumonStatCard(
                  label: 'Cursos',
                  icon: LucideIcons.bookOpen,
                  color: AppColors.sectionCursos,
                  value: cursosAsync.when(data: (c) => '${c.length}', loading: () => '—', error: (_, _) => '—'),
                ),
                AsyncStatCard(
                  label: 'Docentes',
                  icon: LucideIcons.userCheck,
                  color: AppColors.sectionInicio,
                  watch: (ref) => ref.watch(usersCountProvider('docente')),
                ),
                const EdumonStatCard(label: 'Estudiantes', icon: LucideIcons.graduationCap, color: AppColors.sectionForos, value: '—'),
                AsyncStatCard(
                  label: 'Administradores',
                  icon: LucideIcons.userCog,
                  color: AppColors.sectionCalendario,
                  watch: (ref) => ref.watch(usersCountProvider('administrador')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Información institucional', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            institucionAsync.when(
              data: (institucion) {
                if (institucion == null) {
                  return EdumonCard(
                    child: Text('No se encontró información de la institución.', style: TextStyle(color: AppColors.mutedText(context))),
                  );
                }
                return EdumonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(institucion.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (institucion.nit != null) _InfoRow(icon: LucideIcons.hash, text: 'NIT ${institucion.nit}'),
                      if (institucion.direccion != null)
                        _InfoRow(icon: LucideIcons.mapPin, text: institucion.direccion!),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => EdumonCard(
                child: Text('No se pudo cargar la información institucional.', style: TextStyle(color: AppColors.mutedText(context))),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Tu cuenta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            EdumonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.nombreCompleto ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                  _InfoRow(icon: LucideIcons.shieldCheck, text: user?.rol.label ?? ''),
                  if (user?.correo != null) _InfoRow(icon: LucideIcons.mail, text: user!.correo!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Estado del sistema', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            const EdumonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: LucideIcons.circleCheck, text: 'Estado: Activo', color: AppColors.success),
                  _InfoRow(icon: LucideIcons.sparkles, text: 'Plan: Profesional'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.mutedText(context)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color ?? AppColors.mutedText(context), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
