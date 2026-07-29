import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';

/// ---------------------------------------------------------------------------
/// DashboardStatsGrid
///
/// Grid reutilizable para las tarjetas de estadísticas del dashboard.
///
/// Diseño:
///
/// - Móvil pequeño (<600 px): 2 columnas
/// - Tablet/Web: 4 columnas
///
/// Se usa mainAxisExtent en lugar de childAspectRatio porque:
///
/// childAspectRatio calcula el alto según el ancho disponible.
/// En dispositivos muy angostos (320 px, 360 px, etc.) las columnas quedan
/// demasiado estrechas y Flutter reduce también el alto.
///
/// Como EdumonStatCard tiene:
///
/// • icono
/// • texto
/// • número
/// • paddings
///
/// termina necesitando más espacio vertical y aparece:
///
/// RenderFlex overflowed by XX pixels.
///
/// mainAxisExtent fija una altura constante independientemente del ancho.
///
/// ---------------------------------------------------------------------------
class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    final crossAxisCount = breakpoint.isCompact ? 2 : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,

        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,

        // 128 era muy justo.
        // 145 deja espacio suficiente para la mayoría de teléfonos.
        mainAxisExtent: 145,
      ),

      itemCount: children.length,

      itemBuilder: (_, index) => children[index],
    );
  }
}

/// ---------------------------------------------------------------------------
/// AsyncStatCard
///
/// Tarjeta reutilizable que escucha un FutureProvider.
///
/// Mientras carga:
///
///     ——
///
/// Si ocurre un error:
///
///     ——
///
/// Nunca rompe el dashboard completo.
/// ---------------------------------------------------------------------------
class AsyncStatCard extends ConsumerWidget {
  const AsyncStatCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.watch,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final AsyncValue<int> Function(WidgetRef ref) watch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = watch(ref);

    return EdumonStatCard(
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
      value: value.when(
        data: (v) => '$v',
        loading: () => '—',
        error: (_, _) => '—',
      ),
    );
  }
}