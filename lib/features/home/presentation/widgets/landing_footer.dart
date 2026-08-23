import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/decor/edumon_logo_mark.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import 'landing_decor.dart';
import 'scroll_reveal.dart';

/// Footer — imagen "Avatars" (assets/img/recursos/avatars.png) como elemento
/// visual principal, tal como se pidió. Deliberadamente NO incluye redes
/// sociales, teléfono/dirección ni estadísticas: esa información no está
/// confirmada como real (el diseño anterior tenía placeholders como
/// "+57 000 000 0000" y enlaces "#"), y la instrucción explícita es no
/// inventar nada que no exista todavía.
class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final breakpoint = Breakpoint.of(context);

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.backgroundDark : AppColors.eduDark,
      padding: EdgeInsets.symmetric(
        horizontal: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.s24,
        vertical: AppSpacing.s24,
      ),
      child: Stack(
        children: [
          // Fondo oscuro también lleva burbujas, en opacidad baja para que
          // la identidad de marca siga presente en el cierre de la página
          // sin competir con el contenido (pedido explícito: "las burbujas
          // deben aparecer en toda la Home", incluido el footer).
          Positioned.fill(
            child: ScatteredCircles(
              specs: const [
                DecorCircleSpec(asset: 'circulo3.svg', sizeFactor: 0.04, top: 0.04, left: 0.06, opacity: 0.14),
                DecorCircleSpec(asset: 'circulo6.svg', sizeFactor: 0.05, top: 0.1, right: 0.06, opacity: 0.16),
                DecorCircleSpec(asset: 'circulo10.svg', sizeFactor: 0.03, bottom: 0.08, left: 0.15, opacity: 0.12),
                DecorCircleSpec(asset: 'circulo5.svg', sizeFactor: 0.035, bottom: 0.05, right: 0.2, opacity: 0.14),
              ],
            ),
          ),
          Column(
            children: [
              ScrollReveal(
                child: Column(
                  children: [
                    Text(
                      'Familias aprendiendo y creciendo juntas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textInverse.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Marco con gradiente de marca: le da presencia e
                    // integración a la imagen (sin blur/filtros costosos —
                    // solo un borde de color y una sombra suave).
                    Container(
                      constraints: const BoxConstraints(maxWidth: 760),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl2),
                        gradient: const LinearGradient(
                          colors: [AppColors.eduCyan, AppColors.eduPink, AppColors.eduYellow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl2 - 3),
                        child: Image.asset(
                          'assets/img/recursos/avatars.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const EdumonLogoMark(iconSize: 44, wordmarkWidth: 120),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Aprender a criar, un reto a la vez.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textInverse, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  const Icon(LucideIcons.heart, size: 13, color: AppColors.eduPink),
                  Text(
                    'Hecho con cariño en Colombia',
                    style: TextStyle(color: AppColors.textInverse.withValues(alpha: 0.75), fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Por Verónica Mancilla y Bryan Yepes',
                style: TextStyle(color: AppColors.textInverse.withValues(alpha: 0.5), fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 1, color: AppColors.textInverse.withValues(alpha: 0.1)),
              const SizedBox(height: AppSpacing.md),
              Text(
                '© 2026 Edumont. Proyecto educativo para familias.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textInverse.withValues(alpha: 0.45), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
