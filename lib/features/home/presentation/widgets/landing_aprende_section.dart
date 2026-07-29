import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import 'landing_decor.dart';
import 'landing_section_header.dart';

class _Modulo {
  const _Modulo({required this.icon, required this.color, required this.title, required this.desc});
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
}

const _modulos = [
  _Modulo(
    icon: LucideIcons.apple,
    color: AppColors.eduGreen,
    title: 'Alimentación saludable',
    desc: 'Ideas simples para que las comidas en casa sean más sanas y menos peleas.',
  ),
  _Modulo(
    icon: LucideIcons.heartHandshake,
    color: AppColors.eduPurple,
    title: 'Crianza respetuosa',
    desc: 'Acompañar el crecimiento de tu hijo respetando su ritmo y su voz.',
  ),
  _Modulo(
    icon: LucideIcons.smile,
    color: AppColors.eduYellow,
    title: 'Manejo de emociones',
    desc: 'Cómo entender y acompañar lo que siente tu hijo, incluso en las rabietas.',
  ),
  _Modulo(
    icon: LucideIcons.shieldCheck,
    color: AppColors.eduCyan,
    title: 'Límites saludables',
    desc: 'Poner reglas claras sin gritos, con cariño y firmeza al mismo tiempo.',
  ),
  _Modulo(
    icon: LucideIcons.messageCircle,
    color: AppColors.eduPink,
    title: 'Comunicación familiar',
    desc: 'Conversaciones que abren confianza en vez de cerrarla.',
  ),
  _Modulo(
    icon: LucideIcons.sprout,
    color: AppColors.eduGreen,
    title: 'Desarrollo infantil',
    desc: 'Entender qué es esperable en cada etapa para acompañar mejor.',
  ),
  _Modulo(
    icon: LucideIcons.repeat,
    color: AppColors.eduYellow,
    title: 'Hábitos y rutinas',
    desc: 'Rutinas simples que le dan estructura y seguridad al día a día.',
  ),
  _Modulo(
    icon: LucideIcons.users,
    color: AppColors.eduPurple,
    title: 'Tiempo de calidad',
    desc: 'Momentos cortos y significativos que fortalecen el vínculo.',
  ),
  _Modulo(
    icon: LucideIcons.puzzle,
    color: AppColors.eduCyan,
    title: 'Resolución de conflictos',
    desc: 'Herramientas para resolver peleas y desacuerdos sin gritos.',
  ),
  _Modulo(
    icon: LucideIcons.compass,
    color: AppColors.eduPink,
    title: 'Autonomía',
    desc: 'Ayudar a tu hijo a ganar independencia con confianza y sin miedo.',
  ),
  _Modulo(
    icon: LucideIcons.smartphone,
    color: AppColors.eduGreen,
    title: 'Tecnología con medida',
    desc: 'Acuerdos sanos sobre pantallas, sin pelear todos los días por eso.',
  ),
];

/// "¿Qué podrás aprender en Edumont?" — carrusel centrado con efecto de
/// profundidad: la card central se agranda y la que queda al costado se
/// achica, en un solo gesto continuo mientras el usuario arrastra (no hace
/// falta tocar una card para que haga zoom). Reemplaza por completo la
/// sección de testimonios del diseño anterior.
class LandingAprendeSection extends StatelessWidget {
  const LandingAprendeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final breakpoint = Breakpoint.of(context);
    final width = MediaQuery.sizeOf(context).width;

    // viewportFraction controla cuánto se ve de las cards laterales — más
    // angosto en desktop (se ve bastante de los costados), más ancho en
    // móvil (la card central ocupa casi todo, con un pequeño adelanto de
    // la siguiente). Cada valor de breakpoint arma un _ModuleCarousel nuevo
    // (ver `key` más abajo): un PageController no admite cambiar su
    // viewportFraction en caliente, y reemplazarlo a mano en build() es
    // frágil (el controller viejo puede quedar en uso a mitad de frame). Con
    // una ValueKey por breakpoint, Flutter desmonta el carrusel viejo
    // (dispose real vía el framework) y monta uno nuevo limpio.
    final viewportFraction = breakpoint.isCompact ? 0.84 : (breakpoint.isMedium ? 0.6 : 0.36);
    const cardHeight = 300.0;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.4) : AppColors.surface2,
      padding: EdgeInsets.symmetric(vertical: breakpoint.isCompact ? AppSpacing.s24 : AppSpacing.s32),
      child: Stack(
        children: [
          Positioned.fill(
            child: ScatteredCircles(
              specs: const [
                DecorCircleSpec(asset: 'circulo2.svg', sizeFactor: 0.035, top: 0.04, left: 0.04, opacity: 0.3),
                DecorCircleSpec(asset: 'circulo7.svg', sizeFactor: 0.04, top: 0.08, right: 0.06, opacity: 0.3),
                DecorCircleSpec(asset: 'circulo10.svg', sizeFactor: 0.03, bottom: 0.06, left: 0.1, opacity: 0.25),
                DecorCircleSpec(asset: 'circulo5.svg', sizeFactor: 0.035, bottom: 0.1, right: 0.08, opacity: 0.3),
                DecorCircleSpec(asset: 'circulo1.svg', sizeFactor: 0.02, top: 0.35, right: 0.02, opacity: 0.2),
                DecorCircleSpec(asset: 'circulo9.svg', sizeFactor: 0.022, top: 0.4, left: 0.015, opacity: 0.22),
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.s24),
                child: const LandingSectionHeader(
                  eyebrow: 'Módulos de aprendizaje',
                  title: '¿Qué podrás aprender en Edumont?',
                  subtitle:
                      'Cada módulo trae retos prácticos para aplicar con tus hijos '
                      'desde el primer día — nada de teoría complicada.',
                ),
              ),
              SizedBox(height: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.xl),
              _ModuleCarousel(
                key: ValueKey(viewportFraction),
                viewportFraction: viewportFraction,
                cardHeight: cardHeight,
                showArrows: width >= 700,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dueño del PageController — se remonta entero (initState nuevo) cada vez
/// que `LandingAprendeSection` le pasa una `key` distinta por cambio de
/// breakpoint, así el controller siempre nace con el viewportFraction
/// correcto y se dispone de forma normal por el framework.
class _ModuleCarousel extends StatefulWidget {
  const _ModuleCarousel({
    required super.key,
    required this.viewportFraction,
    required this.cardHeight,
    required this.showArrows,
    required this.isDark,
  });

  final double viewportFraction;
  final double cardHeight;
  final bool showArrows;
  final bool isDark;

  @override
  State<_ModuleCarousel> createState() => _ModuleCarouselState();
}

class _ModuleCarouselState extends State<_ModuleCarousel> {
  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction)..addListener(_onPageChange);
  }

  void _onPageChange() {
    final page = _pageController.page;
    if (page == null) return;
    setState(() => _page = page);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChange);
    _pageController.dispose();
    super.dispose();
  }

  void _shift(int delta) {
    final current = _pageController.hasClients ? (_pageController.page ?? _page) : _page;
    final target = (current.round() + delta).clamp(0, _modulos.length - 1);
    _pageController.animateToPage(target, duration: AppDurations.slow, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      children: [
        SizedBox(
          height: widget.cardHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _modulos.length,
            itemBuilder: (context, index) {
              final delta = (index - _page).clamp(-1.5, 1.5).abs();
              final scale = (1 - delta * 0.22).clamp(0.72, 1.0);
              final opacity = (1 - delta * 0.55).clamp(0.35, 1.0);
              return Center(
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      // El scale/opacity cambia en cada frame mientras se
                      // arrastra — RepaintBoundary aísla la capa de cada
                      // card para que el motor solo recomponga la
                      // transformación en vez de repintar ícono/texto en
                      // cada frame del gesto.
                      child: RepaintBoundary(
                        child: _ModuloCard(modulo: _modulos[index], isDark: isDark, isCentral: delta < 0.5),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showArrows) ...[
              _CarouselArrow(icon: LucideIcons.chevronLeft, onTap: () => _shift(-1), isDark: isDark),
              const SizedBox(width: AppSpacing.md),
            ],
            ...List.generate(_modulos.length, (i) {
              final active = (_page.round() == i);
              return AnimatedContainer(
                duration: AppDurations.base,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : (isDark ? AppColors.borderNormalDark : AppColors.neutral200),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              );
            }),
            if (widget.showArrows) ...[
              const SizedBox(width: AppSpacing.md),
              _CarouselArrow(icon: LucideIcons.chevronRight, onTap: () => _shift(1), isDark: isDark),
            ],
          ],
        ),
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap, required this.isDark});
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ModuloCard extends StatefulWidget {
  const _ModuloCard({required this.modulo, required this.isDark, required this.isCentral});
  final _Modulo modulo;
  final bool isDark;
  final bool isCentral;

  @override
  State<_ModuloCard> createState() => _ModuloCardState();
}

class _ModuloCardState extends State<_ModuloCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hoverBoost = (_hover && widget.isCentral) ? 1.03 : 1.0;
    final pressShrink = _pressed ? 0.98 : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: AppDurations.fast,
          scale: hoverBoost * pressShrink,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: EdumonCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 5, decoration: BoxDecoration(color: widget.modulo.color)),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: widget.modulo.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(widget.modulo.icon, color: widget.modulo.color, size: 24),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.modulo.title,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.modulo.desc,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.mutedText(context)),
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
    );
  }
}
