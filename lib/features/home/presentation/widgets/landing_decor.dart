import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

/// Reconstrucción nativa del recurso "Círculo Degradé"
/// (assets/img/recursos/Circulodegradado.svg): un anillo con gradiente
/// angular (verde→cian→rosa→amarillo→verde) y centro blanco.
///
/// El archivo original lo exporta Figma con un `<foreignObject>` +
/// `conic-gradient` CSS embebido, que flutter_svg no soporta (solo entiende
/// SVG puro) — se renderizaría sin color. Se reproduce la misma paleta con
/// [SweepGradient], usando los tokens oficiales de AppColors en vez de los
/// hex sueltos del export, para quedar alineado con la identidad de marca.
class GradientRingBackdrop extends StatelessWidget {
  const GradientRingBackdrop({super.key, required this.size, this.thickness = 0.084});

  final double size;

  /// Grosor del anillo como fracción del tamaño total (0.084 ≈ el 25/300
  /// original del SVG fuente).
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            AppColors.eduGreen,
            AppColors.eduCyan,
            AppColors.eduPink,
            AppColors.eduYellow,
            AppColors.eduGreen,
          ],
          stops: [0.0, 0.1797, 0.50, 0.7188, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * thickness),
        // Centro "hueco" del anillo — coincide con la superficie de fondo de
        // la sección (no un blanco fijo) para que se siga leyendo como anillo
        // en vez de disco sólido también en modo oscuro.
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Un círculo decorativo de assets/img/circulos/ posicionado de forma
/// fraccional (0..1) sobre el tamaño de su sección — así escala solo con
/// cada pantalla en vez de quedar fijo en píxeles.
class DecorCircleSpec {
  const DecorCircleSpec({
    required this.asset,
    required this.sizeFactor,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.opacity = 0.55,
    this.rotation = 0,
  });

  final String asset;

  /// Tamaño del círculo como fracción del ancho disponible de la sección.
  final double sizeFactor;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double opacity;
  final double rotation;
}

/// Capa de fondo con círculos decorativos dispersos — BLUEPRINT visual:
/// "deben aparecer detrás del contenido, ayudar a generar profundidad, no
/// dificultar la lectura, adaptarse al tamaño de cada pantalla". Se ignora
/// en el hit-testing para no interceptar toques sobre el contenido real.
class ScatteredCircles extends StatelessWidget {
  const ScatteredCircles({super.key, required this.specs});

  final List<DecorCircleSpec> specs;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
          final h = constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
          return Stack(
            children: [
              for (final s in specs)
                Positioned(
                  top: s.top != null ? s.top! * h : null,
                  bottom: s.bottom != null ? s.bottom! * h : null,
                  left: s.left != null ? s.left! * w : null,
                  right: s.right != null ? s.right! * w : null,
                  child: Opacity(
                    opacity: s.opacity,
                    child: Transform.rotate(
                      angle: s.rotation,
                      child: SvgPicture.asset(
                        'assets/img/circulos/${s.asset}',
                        width: (w * s.sizeFactor).clamp(24, 260),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
