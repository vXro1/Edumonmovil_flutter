import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Card claymórfica — BLUEPRINT.md FASE 2.1 / FASE 6.
class EdumonCard extends StatelessWidget {
  const EdumonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isDark ? Border.all(color: AppColors.borderNormalDark) : null,
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Stat card compacta para dashboards — BLUEPRINT.md FASE 3.2.
class EdumonStatCard extends StatelessWidget {
  const EdumonStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Si se pasa, la card se vuelve tappable (ripple vía EdumonCard) y navega
  /// a una vista con el detalle — evita que la card "parezca botón" sin
  /// serlo. Si es null, la card queda puramente informativa.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return EdumonCard(
      onTap: onTap,
      // Sin mainAxisSize.min a propósito: la card recibe una altura acotada
      // (viene de un GridView con mainAxisExtent fijo) y este Column debe
      // ocupar ese alto completo para que el Spacer pueda repartir el
      // espacio sobrante — así el título nunca fuerza más alto del que hay
      // disponible, sin importar el tamaño del dispositivo.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
          const Spacer(),
          // FittedBox como último resguardo: si un factor de escala de texto
          // grande (accesibilidad) igual empuja el contenido más allá del
          // alto fijo del grid, el valor se achica en vez de desbordar.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de "sin datos" reutilizable — evita duplicar el mismo patrón en
/// cada pantalla con listas que pueden estar vacías.
class EdumonEmptyHint extends StatelessWidget {
  const EdumonEmptyHint({super.key, required this.text, this.icon = LucideIcons.info});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return EdumonCard(
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppColors.textSubtleDark : AppColors.textSubtle, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
