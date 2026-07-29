import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import 'scroll_reveal.dart';

/// Encabezado reutilizable de sección: eyebrow con ícono + título + subtítulo
/// opcional, centrado. Usado por todas las secciones del Home para mantener
/// un mismo ritmo visual.
class LandingSectionHeader extends StatelessWidget {
  const LandingSectionHeader({super.key, required this.eyebrow, required this.title, this.subtitle});

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final compact = Breakpoint.of(context).isCompact;

    return ScrollReveal(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 13, color: AppColors.primaryHover),
                const SizedBox(width: 6),
                Text(
                  eyebrow,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryHover),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: compact ? 26 : 34,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.5, height: 1.6, color: AppColors.mutedText(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
