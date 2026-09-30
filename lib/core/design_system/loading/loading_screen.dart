import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

/// Mismos colores del logo (assets/img/logo/logo.svg) — así las burbujas se
/// sienten parte de la marca en vez de decoración genérica.
const _bubbleColors = [
  Color(0xFF0DC5E2),
  Color(0xFF71C83A),
  Color(0xFFF12474),
  Color(0xFFFDBA03),
  Color(0xFF8421CD),
  Color(0xFFFC5891),
];

/// Pantalla de carga full-screen — BLUEPRINT.md FASE 6.
/// Logo animado + burbujas de colores flotando a su alrededor, en vez del
/// spinner genérico anterior — mismo tratamiento que LoadingScreen.jsx web.
class LoadingScreenWidget extends StatefulWidget {
  const LoadingScreenWidget({super.key, this.message});

  final String? message;

  @override
  State<LoadingScreenWidget> createState() => _LoadingScreenWidgetState();
}

class _LoadingScreenWidgetState extends State<LoadingScreenWidget> with SingleTickerProviderStateMixin {
  // un solo controller maneja todas las animaciones (halo, burbujas, logo,
  // puntitos): cada una deriva su propia fase/frecuencia de este mismo valor
  // 0..1 en bucle, en vez de un AnimationController por efecto.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Halo(t: _controller.value),
                    for (var i = 0; i < _bubbleColors.length; i++)
                      _Bubble(
                        color: _bubbleColors[i],
                        angle: (2 * math.pi / _bubbleColors.length) * i,
                        t: _controller.value,
                        phaseSeconds: i * 0.18,
                        size: 9.0 + (i % 3) * 4,
                      ),
                    _BreathingLogo(t: _controller.value),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                children: [
                  const TextSpan(text: 'Edu'),
                  TextSpan(text: 'mon', style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _AnimatedMessage(
                message: widget.message ?? 'Cargando, espera un momento',
                t: _controller.value,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    // periodo ~1.8s dentro del ciclo maestro de 6s
    final wave = math.sin(t * 2 * math.pi * (6 / 1.8));
    final scale = 0.9 + 0.25 * (0.5 + 0.5 * wave);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [AppColors.primary.withValues(alpha: 0.14), AppColors.primary.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.color, required this.angle, required this.t, required this.phaseSeconds, required this.size});

  final Color color;
  final double angle;
  final double t;
  final double phaseSeconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    const radius = 58.0;
    const masterSeconds = 6.0;
    const floatPeriodSeconds = 2.4;
    final phaseFraction = phaseSeconds / masterSeconds;
    final wave = math.sin((t + phaseFraction) * 2 * math.pi * (masterSeconds / floatPeriodSeconds));
    final lift = 0.5 + 0.5 * wave; // 0..1
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius - (lift * 10);
    final scale = 1 + 0.2 * lift;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _BreathingLogo extends StatelessWidget {
  const _BreathingLogo({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    const masterSeconds = 6.0;
    const breathePeriodSeconds = 1.7;
    final wave = math.sin(t * 2 * math.pi * (masterSeconds / breathePeriodSeconds));
    final lift = 0.5 + 0.5 * wave; // 0..1
    return Transform.rotate(
      angle: -0.07 * wave,
      child: Transform.scale(
        scale: 1 + 0.1 * lift,
        child: SvgPicture.asset('assets/img/logo/logo.svg', width: 62, height: 62),
      ),
    );
  }
}

class _AnimatedMessage extends StatelessWidget {
  const _AnimatedMessage({required this.message, required this.t, required this.color});

  final String message;
  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 4),
        for (var i = 0; i < 3; i++) _Dot(t: t, phaseSeconds: i * 0.2, color: color),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.t, required this.phaseSeconds, required this.color});

  final double t;
  final double phaseSeconds;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const masterSeconds = 6.0;
    const dotPeriodSeconds = 1.2;
    final phaseFraction = phaseSeconds / masterSeconds;
    final wave = math.sin((t + phaseFraction) * 2 * math.pi * (masterSeconds / dotPeriodSeconds));
    final lift = 0.5 + 0.5 * wave; // 0..1
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Opacity(
        opacity: 0.25 + 0.75 * lift,
        child: Transform.translate(
          offset: Offset(0, -2 * lift),
          child: Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ),
      ),
    );
  }
}
