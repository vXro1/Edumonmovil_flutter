import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import 'landing_decor.dart';
import 'scroll_reveal.dart';

/// Hero principal — BLUEPRINT visual: "Círculo Degradé" de fondo + "Edumont
/// Cuerpo Completo" (assets/img/logo/avatarprincipal.svg) encima, como una
/// sola composición centrada y responsive.
class LandingHero extends StatelessWidget {
  const LandingHero({super.key, required this.onPrimaryCta, required this.onSecondaryCta});

  final VoidCallback onPrimaryCta;
  final VoidCallback onSecondaryCta;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final breakpoint = Breakpoint.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final mascotSize = width.clamp(320, 1600) * (breakpoint.isCompact ? 0.62 : 0.26);
    final clampedMascotSize = mascotSize.clamp(200.0, 460.0);

    final textColumn = Column(
      crossAxisAlignment: breakpoint.isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        ScrollReveal(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primaryHover),
                const SizedBox(width: 6),
                // Flexible es necesario: con mainAxisSize.min el Row se mide a
                // su ancho natural sin límite, así que en pantallas angostas
                // este texto largo se salía del Row (RenderFlex overflow) en
                // vez de ajustarse. Flexible le permite envolver en 2 líneas.
                Flexible(
                  child: Text(
                    'Hecho para acompañar a las familias',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryHover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ScrollReveal(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Aprender a criar,\nun reto a la vez',
            textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: breakpoint.isCompact ? 36 : 52,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ScrollReveal(
          delay: const Duration(milliseconds: 160),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Edumont te acompaña como padre o madre con retos prácticos y '
              'consejos fáciles de aplicar en casa: alimentación, emociones, '
              'límites y mucho más, un paso a la vez junto a tus hijos.',
              textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ScrollReveal(
          delay: const Duration(milliseconds: 240),
          child: Wrap(
            alignment: breakpoint.isCompact ? WrapAlignment.center : WrapAlignment.start,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              EdumonButton(
                label: 'Quiero saber más',
                rightIcon: LucideIcons.arrowRight,
                size: EdumonButtonSize.lg,
                onPressed: onPrimaryCta,
              ),
              EdumonButton(
                label: 'Ver qué aprenderás',
                leftIcon: LucideIcons.play,
                variant: EdumonButtonVariant.outline,
                size: EdumonButtonSize.lg,
                onPressed: onSecondaryCta,
              ),
            ],
          ),
        ),
      ],
    );

    final mascotComposition = ScrollReveal(
      delay: const Duration(milliseconds: 120),
      child: SizedBox(
        width: clampedMascotSize * 1.05,
        height: clampedMascotSize * 1.05,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GradientRingBackdrop(size: clampedMascotSize),
            SvgPicture.asset('assets/img/logo/avatarprincipal.svg', width: clampedMascotSize * 0.86),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: ScatteredCircles(
            specs: const [
              DecorCircleSpec(asset: 'circulo9.svg', sizeFactor: 0.05, top: 0.06, left: 0.06, opacity: 0.5),
              DecorCircleSpec(asset: 'circulo10.svg', sizeFactor: 0.035, top: 0.16, left: 0.14, opacity: 0.4),
              DecorCircleSpec(asset: 'circulo6.svg', sizeFactor: 0.045, top: 0.10, right: 0.08, opacity: 0.45),
              DecorCircleSpec(asset: 'circulo3.svg', sizeFactor: 0.03, bottom: 0.12, left: 0.30, opacity: 0.35),
              DecorCircleSpec(asset: 'circulo11.svg', sizeFactor: 0.04, bottom: 0.06, right: 0.22, opacity: 0.4),
              DecorCircleSpec(asset: 'circulo2.svg', sizeFactor: 0.022, top: 0.28, left: 0.42, opacity: 0.3),
              DecorCircleSpec(asset: 'circulo4.svg', sizeFactor: 0.028, top: 0.04, right: 0.32, opacity: 0.32),
              DecorCircleSpec(asset: 'circulo12.svg', sizeFactor: 0.02, bottom: 0.24, right: 0.04, opacity: 0.28),
              DecorCircleSpec(asset: 'circulo7.svg', sizeFactor: 0.018, bottom: 0.3, left: 0.06, opacity: 0.25),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.s24,
            vertical: breakpoint.isCompact ? AppSpacing.s24 : AppSpacing.s32,
          ),
          child: breakpoint.isCompact
              ? Column(
                  children: [
                    textColumn,
                    const SizedBox(height: AppSpacing.xl),
                    mascotComposition,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: textColumn),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(flex: 5, child: Center(child: mascotComposition)),
                  ],
                ),
        ),
      ],
    );
  }
}
