import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Input estilo Duolingo — BLUEPRINT.md FASE 2.12 / FASE 6.
/// Estados error (shake + borde rojo) y success (borde verde).
class EdumonTextField extends StatefulWidget {
  const EdumonTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.leftIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
    this.prefixText,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? leftIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? prefixText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final List<String>? autofillHints;

  @override
  State<EdumonTextField> createState() => _EdumonTextFieldState();
}

class _EdumonTextFieldState extends State<EdumonTextField> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _obscure = true;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(covariant EdumonTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != null && widget.errorText != _lastError) {
      _shakeController.forward(from: 0);
    }
    _lastError = widget.errorText;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final field = TextField(
      controller: widget.controller,
      obscureText: widget.obscureText ? _obscure : false,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.obscureText ? null : widget.minLines,
      autofillHints: widget.autofillHints,
      style: TextStyle(fontSize: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixText: widget.prefixText,
        prefixIcon: widget.leftIcon != null
            ? Icon(
                widget.leftIcon,
                color: hasError ? AppColors.error : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
              )
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final dx = t == 0 ? 0.0 : (8 * (1 - t)) * ((t * 24).floor().isEven ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
        child: field,
      ),
    );
  }
}
