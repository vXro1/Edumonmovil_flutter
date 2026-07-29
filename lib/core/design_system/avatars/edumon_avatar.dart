import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';

/// Avatar circular de marca EDUMON.
///
/// A diferencia de un `CircleAvatar` con `backgroundImage`, esto NUNCA
/// recorta cabezas/rostros: la imagen se ajusta con [BoxFit.contain] dentro
/// del círculo (con relleno de fondo si la imagen no es cuadrada) en vez de
/// [BoxFit.cover]. Soporta un borde con degradado de marca (para contextos
/// prominentes: foto de perfil, selector de avatar) y una transición
/// fade+scale al cambiar de imagen.
class EdumonAvatar extends StatefulWidget {
  const EdumonAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.radius = 20,
    this.fallbackText,
    this.fallbackIcon,
    this.fallbackColor,
    this.backgroundColor,
    this.showBorder = false,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  /// URL de red del avatar. Si es null (o falla la carga) se usa el
  /// fallback ([fallbackText] o [fallbackIcon]).
  final String? imageUrl;

  /// Alternativa a [imageUrl] para imágenes locales (ej. `MemoryImage`)
  /// mientras se sube una nueva foto antes de tener URL definitiva.
  final ImageProvider? imageProvider;

  final double radius;
  final String? fallbackText;
  final IconData? fallbackIcon;

  /// Color del texto/ícono de fallback — por defecto `AppColors.primary`.
  /// Útil para codificar por color según rol (ej. `_roleColor(user.rol)`).
  final Color? fallbackColor;
  final Color? backgroundColor;

  /// Anillo con degradado de marca — reservado para avatares prominentes
  /// (foto de perfil propia, selector de avatar). En listas densas se deja
  /// en `false` para no saturar visualmente la fila.
  final bool showBorder;

  /// Resalta el anillo (ej. avatar elegido en un selector).
  final bool selected;

  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<EdumonAvatar> createState() => _EdumonAvatarState();
}

class _EdumonAvatarState extends State<EdumonAvatar> {
  bool _pressed = false;

  static const _gradientColors = [
    AppColors.eduCyan,
    AppColors.eduPink,
    AppColors.eduPurple,
    AppColors.eduGreen,
    AppColors.eduCyan,
  ];

  ImageProvider? get _provider {
    if (widget.imageProvider != null) return widget.imageProvider;
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) return NetworkImage(widget.imageUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = widget.radius * 2;
    final provider = _provider;

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.backgroundColor ?? (isDark ? AppColors.surface2Dark : AppColors.primaryLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
        ),
        child: provider != null
            ? Image(
                key: ValueKey(widget.imageUrl ?? provider.hashCode),
                image: provider,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _Fallback(
                  key: const ValueKey('fallback'),
                  text: widget.fallbackText,
                  icon: widget.fallbackIcon,
                  color: widget.fallbackColor,
                  radius: widget.radius,
                ),
              )
            : _Fallback(
                key: const ValueKey('fallback'),
                text: widget.fallbackText,
                icon: widget.fallbackIcon,
                color: widget.fallbackColor,
                radius: widget.radius,
              ),
      ),
    );

    if (widget.showBorder) {
      final borderWidth = widget.radius >= 32 ? 3.0 : 2.0;
      circle = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(colors: _gradientColors),
          boxShadow: widget.selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: circle,
      );
    }

    if (widget.semanticLabel != null) {
      circle = Semantics(label: widget.semanticLabel, image: true, child: circle);
    }

    if (widget.onTap == null) return circle;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _pressed ? 0.92 : 1.0,
        child: circle,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({super.key, this.text, this.icon, this.color, required this.radius});
  final String? text;
  final IconData? icon;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.primary;
    if (text != null && text!.isNotEmpty) {
      return Center(
        child: Text(
          text!,
          style: TextStyle(color: resolvedColor, fontWeight: FontWeight.w700, fontSize: radius * 0.7),
        ),
      );
    }
    return Center(child: Icon(icon ?? LucideIcons.user, color: resolvedColor, size: radius));
  }
}
