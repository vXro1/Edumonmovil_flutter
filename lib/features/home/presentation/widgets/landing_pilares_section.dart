import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import 'landing_decor.dart';
import 'landing_section_header.dart';
import 'scroll_reveal.dart';

class _Pilar {
  const _Pilar({required this.icon, required this.color, required this.title, required this.desc});
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
}

const _pilares = [
  _Pilar(
    icon: LucideIcons.target,
    color: AppColors.eduCyan,
    title: 'Retos fáciles de aplicar en casa',
    desc: 'Cada reto es un paso concreto que podés poner en práctica con tu '
        'hijo o hija ese mismo día, sin complicaciones ni teoría de más.',
  ),
  _Pilar(
    icon: LucideIcons.heart,
    color: AppColors.eduPink,
    title: 'Tu familia, siempre en el centro',
    desc: 'Acompañamos el momento que estás viviendo como padre o madre, '
        'con contenido pensado para tu día a día real, no genérico.',
  ),
  _Pilar(
    icon: LucideIcons.sparkles,
    color: AppColors.eduYellow,
    title: 'Cada avance se reconoce',
    desc: 'A medida que completás retos vas viendo tu progreso — pequeños '
        'logros que motivan a seguir aprendiendo junto a tus hijos.',
  ),
];

/// "Por qué Edumont" — versión reformulada de la sección "Pilares" del
/// diseño anterior, hablando directo al padre/madre en vez de a
/// instituciones/docentes.
class LandingPilaresSection extends StatelessWidget {
  const LandingPilaresSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final breakpoint = Breakpoint.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: ScatteredCircles(
            specs: const [
              DecorCircleSpec(asset: 'circulo1.svg', sizeFactor: 0.04, top: 0.03, right: 0.1, opacity: 0.3),
              DecorCircleSpec(asset: 'circulo8.svg', sizeFactor: 0.03, top: 0.4, left: 0.03, opacity: 0.25),
              DecorCircleSpec(asset: 'circulo6.svg', sizeFactor: 0.045, bottom: 0.04, right: 0.04, opacity: 0.3),
              DecorCircleSpec(asset: 'circulo11.svg', sizeFactor: 0.025, bottom: 0.15, left: 0.2, opacity: 0.22),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.s24,
            vertical: AppSpacing.s24,
          ),
          child: Column(
            children: [
              const LandingSectionHeader(
                eyebrow: 'Por qué Edumont',
                title: 'Acompañamos tu forma de criar',
              ),
              const SizedBox(height: AppSpacing.xl),
              breakpoint.isCompact
                  ? Column(children: [for (final p in _pilares) _PilarCard(pilar: p, isDark: isDark)])
                  // CrossAxisAlignment.start (no .stretch): esta Row vive en un
                  // Column sin alto acotado (la página es un SingleChildScrollView),
                  // así que .stretch le pasaría altura infinita a cada Expanded —
                  // Flutter lo revienta con un assert en debug y en release lo
                  // calcula en silencio con un tamaño roto. Se probó también
                  // envolver en IntrinsicHeight para mantener las 3 tarjetas con
                  // igual alto, pero el alto que mide ahí no siempre alcanza para
                  // el contenido real una vez que Expanded angosta cada tarjeta
                  // (el ancho usado para medir el intrínseco no es el ancho final),
                  // y volvía a overflowear. Sin igualar alturas no hay ninguna
                  // restricción infinita ni desajuste posible — cada tarjeta usa
                  // su alto natural.
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final p in _pilares)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              child: _PilarCard(pilar: p, isDark: isDark),
                            ),
                          ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PilarCard extends StatefulWidget {
  const _PilarCard({required this.pilar, required this.isDark});
  final _Pilar pilar;
  final bool isDark;

  @override
  State<_PilarCard> createState() => _PilarCardState();
}

class _PilarCardState extends State<_PilarCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lift = _hover ? -6.0 : 0.0;
    final pressScale = _pressed ? 0.98 : 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ScrollReveal(
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          cursor: SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              duration: AppDurations.fast,
              scale: pressScale,
              child: AnimatedContainer(
                duration: AppDurations.base,
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, lift, 0),
                child: EdumonCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 4, color: widget.pilar.color),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: widget.pilar.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(widget.pilar.icon, color: widget.pilar.color, size: 26),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              widget.pilar.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.pilar.desc,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
