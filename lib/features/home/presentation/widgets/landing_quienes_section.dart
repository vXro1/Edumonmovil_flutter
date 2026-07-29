import 'package:flutter/material.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import 'landing_decor.dart';
import 'scroll_reveal.dart';

class _Miembro {
  const _Miembro({required this.iniciales, required this.nombre, required this.rol, required this.colors});
  final String iniciales;
  final String nombre;
  final String rol;
  final List<Color> colors;
}

const _equipo = [
  _Miembro(
    iniciales: 'VM',
    nombre: 'Verónica Mancilla',
    rol: 'Diseño UX/UI',
    colors: [AppColors.eduPink, AppColors.pink200],
  ),
  _Miembro(
    iniciales: 'BY',
    nombre: 'Bryan Yepes',
    rol: 'Desarrollo Backend',
    colors: [AppColors.eduCyan, AppColors.cyan200],
  ),
];

/// "Quiénes somos" — misma historia real del equipo del diseño anterior
/// (nada inventado: dos estudiantes colombianos), con la narrativa ajustada
/// al propósito real de Edumont: acompañar a las familias, no a colegios.
class LandingQuienesSection extends StatelessWidget {
  const LandingQuienesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final breakpoint = Breakpoint.of(context);

    final textColumn = Column(
      crossAxisAlignment: breakpoint.isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const LandingSectionHeaderLeft(eyebrow: 'Quiénes somos'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nacimos pensando en las familias',
          textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: breakpoint.isCompact ? 26 : 32,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Edumont es un proyecto educativo creado por dos estudiantes '
          'colombianos, con la convicción de que la crianza se acompaña '
          'mejor cuando los padres tienen herramientas simples y a la mano.',
          textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
          style: TextStyle(fontSize: 15, height: 1.7, color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Empezó como un proyecto de aula y creció con un propósito real: '
          'ayudar a cada familia a convertir el conocimiento en retos '
          'prácticos que se pueden vivir en casa, día a día.',
          textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
          style: TextStyle(fontSize: 15, height: 1.7, color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Hecho con esfuerzo, código y mucho cariño por la crianza.',
          textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ],
    );

    // En compacto, cada card de equipo pasa a ocupar el ancho completo en
    // formato horizontal (avatar + texto) en vez de dos mitades angostas
    // lado a lado — más cómodo de leer en móvil, sin quedar apretado.
    final teamRow = breakpoint.isCompact
        ? Column(
            children: [
              for (final m in _equipo) ...[
                _MiembroCardHorizontal(miembro: m, isDark: isDark),
                if (m != _equipo.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          )
        : Column(children: [for (final m in _equipo) _MiembroCard(miembro: m, isDark: isDark)]);

    return Stack(
      children: [
        Positioned.fill(
          child: ScatteredCircles(
            specs: const [
              DecorCircleSpec(asset: 'circulo4.svg', sizeFactor: 0.04, top: 0.08, right: 0.05, opacity: 0.3),
              DecorCircleSpec(asset: 'circulo12.svg', sizeFactor: 0.03, bottom: 0.1, left: 0.06, opacity: 0.3),
              DecorCircleSpec(asset: 'circulo1.svg', sizeFactor: 0.025, top: 0.04, left: 0.12, opacity: 0.22),
              DecorCircleSpec(asset: 'circulo8.svg', sizeFactor: 0.035, bottom: 0.02, right: 0.22, opacity: 0.25),
              DecorCircleSpec(asset: 'circulo5.svg', sizeFactor: 0.02, top: 0.4, right: 0.02, opacity: 0.2),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.s24,
            vertical: AppSpacing.s24,
          ),
          child: ScrollReveal(
            child: breakpoint.isCompact
                ? Column(children: [textColumn, const SizedBox(height: AppSpacing.lg), teamRow])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: textColumn),
                      const SizedBox(width: AppSpacing.xl),
                      SizedBox(width: 220, child: teamRow),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _MiembroCard extends StatelessWidget {
  const _MiembroCard({required this.miembro, required this.isDark});
  final _Miembro miembro;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      child: EdumonCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: miembro.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                miembro.iniciales,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              miembro.nombre,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            Text(
              miembro.rol,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.mutedText(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Variante horizontal (avatar a la izquierda, texto a la derecha) para
/// cuando la card ocupa el ancho completo en pantallas compactas.
class _MiembroCardHorizontal extends StatelessWidget {
  const _MiembroCardHorizontal({required this.miembro, required this.isDark});
  final _Miembro miembro;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return EdumonCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: miembro.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              miembro.iniciales,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  miembro.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(miembro.rol, style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Variante alineada a la izquierda del eyebrow (LandingSectionHeader
/// siempre centra) — usada donde el resto de la sección no está centrado.
class LandingSectionHeaderLeft extends StatelessWidget {
  const LandingSectionHeaderLeft({super.key, required this.eyebrow});
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(
        eyebrow,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryHover),
      ),
    );
  }
}
