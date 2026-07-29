import 'package:flutter/material.dart';

/// Aparición progresiva al hacer scroll — fade + slide sutil hacia arriba,
/// una sola vez por widget (no se re-oculta al salir de pantalla). Sin
/// dependencias externas: se engancha directo a la posición de scroll del
/// [Scrollable] ancestro más cercano (la página del Home).
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;

  /// Retraso antes de animar — usado para escalonar (stagger) listas de cards.
  final Duration delay;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  bool _visible = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _position) {
      _position?.removeListener(_checkVisibility);
      _position = newPosition;
      _position?.addListener(_checkVisibility);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    _position?.removeListener(_checkVisibility);
    super.dispose();
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final position = renderObject.localToGlobal(Offset.zero);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    if (position.dy < viewportHeight * 0.88) {
      if (widget.delay == Duration.zero) {
        setState(() => _visible = true);
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) setState(() => _visible = true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un solo TweenAnimationBuilder maneja fade + slide juntos (en vez de
    // AnimatedOpacity + AnimatedSlide apilados, dos AnimationController
    // implícitos por card) — con decenas de cards en pantalla, reduce a la
    // mitad la cantidad de animaciones simultáneas corriendo en la página.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _visible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
        );
      },
      child: widget.child,
    );
  }
}
