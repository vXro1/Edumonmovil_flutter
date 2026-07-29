import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum EdumonButtonVariant { primary, secondary, accent, success, danger, warning, ghost, outline }

enum EdumonButtonSize { xs, sm, md, lg, xl }

/// Botón "Duolingo 3D-press" — BLUEPRINT.md FASE 2.1 / FASE 6.
/// Sombra inferior sólida que colapsa a 0 y el botón baja al presionar.
class EdumonButton extends StatefulWidget {
  const EdumonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = EdumonButtonVariant.primary,
    this.size = EdumonButtonSize.md,
    this.leftIcon,
    this.rightIcon,
    this.fullWidth = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EdumonButtonVariant variant;
  final EdumonButtonSize size;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final bool fullWidth;
  final bool loading;

  @override
  State<EdumonButton> createState() => _EdumonButtonState();
}

class _EdumonButtonState extends State<EdumonButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.loading;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  _ButtonPalette get _palette {
    switch (widget.variant) {
      case EdumonButtonVariant.primary:
        return _ButtonPalette(AppColors.primary, AppColors.shadowBtnPrimary, AppColors.textInverse);
      case EdumonButtonVariant.secondary:
        return _ButtonPalette(AppColors.secondary, AppColors.secondaryHover, AppColors.textInverse);
      case EdumonButtonVariant.accent:
        return _ButtonPalette(AppColors.accent, AppColors.accentHover, AppColors.textInverse);
      case EdumonButtonVariant.success:
        return _ButtonPalette(AppColors.success, AppColors.shadowBtnSuccess, AppColors.textInverse);
      case EdumonButtonVariant.danger:
        return _ButtonPalette(AppColors.error, AppColors.shadowBtnDanger, AppColors.textInverse);
      case EdumonButtonVariant.warning:
        return _ButtonPalette(AppColors.warning, AppColors.shadowBtnWarning, AppColors.textPrimary);
      case EdumonButtonVariant.ghost:
        return _ButtonPalette(
          Colors.transparent,
          Colors.transparent,
          _isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        );
      case EdumonButtonVariant.outline:
        return _ButtonPalette(
          _isDark ? AppColors.surfaceDark : AppColors.surface,
          _isDark ? AppColors.borderNormalDark : AppColors.borderNormal,
          _isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        );
    }
  }

  ({double height, double vPad, double hPad, double fontSize, double iconSize}) get _dims {
    switch (widget.size) {
      case EdumonButtonSize.xs:
        return (height: 32, vPad: 9, hPad: 12, fontSize: 12, iconSize: 14);
      case EdumonButtonSize.sm:
        return (height: 38, vPad: 11, hPad: 16, fontSize: 14, iconSize: 16);
      case EdumonButtonSize.md:
        return (height: 44, vPad: 12, hPad: 20, fontSize: 16, iconSize: 18);
      case EdumonButtonSize.lg:
        return (height: 52, vPad: 16, hPad: 24, fontSize: 17, iconSize: 20);
      case EdumonButtonSize.xl:
        return (height: 60, vPad: 19, hPad: 28, fontSize: 18, iconSize: 22);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final dims = _dims;
    final isFlat = widget.variant == EdumonButtonVariant.ghost;
    const shadowOffset = 5.0;

    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: dims.iconSize,
            height: dims.iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: palette.foreground),
          )
        else if (widget.leftIcon != null)
          Icon(widget.leftIcon, size: dims.iconSize, color: palette.foreground),
        if (widget.loading || widget.leftIcon != null) const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.foreground.withValues(alpha: _disabled ? 0.6 : 1),
              fontSize: dims.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.rightIcon != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(widget.rightIcon, size: dims.iconSize, color: palette.foreground),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        onTap: _disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          width: widget.fullWidth ? double.infinity : null,
          constraints: BoxConstraints(minHeight: dims.height),
          padding: EdgeInsets.symmetric(horizontal: dims.hPad, vertical: dims.vPad),
          transform: Matrix4.translationValues(0, (_pressed && !isFlat) ? shadowOffset : 0, 0),
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: _disabled ? 0.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: widget.variant == EdumonButtonVariant.outline
                ? Border.all(color: palette.shadow, width: 2)
                : null,
            boxShadow: isFlat || _disabled
                ? null
                : [
                    BoxShadow(
                      color: palette.shadow,
                      offset: Offset(0, _pressed ? 0 : shadowOffset),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

class _ButtonPalette {
  const _ButtonPalette(this.background, this.shadow, this.foreground);
  final Color background;
  final Color shadow;
  final Color foreground;
}
