import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/edumon_button.dart';

enum EdumonDialogVariant { error, warning, success, info }

/// Modal centrado y reutilizable para errores, advertencias, éxito e
/// información — reemplaza los banners inline dentro de formularios que
/// obligaban a hacer scroll hasta el tope de la card para verse.
///
/// Bloquea la interacción con el fondo (no se puede descartar tocando
/// afuera) y siempre requiere que el usuario toque un botón para cerrarlo.
class EdumonDialog {
  const EdumonDialog._();

  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    EdumonDialogVariant variant = EdumonDialogVariant.error,
    String buttonLabel = 'Aceptar',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _specFor(variant);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EdumonDialogShell(
        icon: spec.icon,
        iconColor: spec.color,
        iconBg: spec.surface(isDark),
        title: title ?? spec.defaultTitle,
        message: message,
        actions: [
          EdumonButton(
            label: buttonLabel,
            variant: spec.buttonVariant,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// Confirmación con dos botones — devuelve `true` solo si el usuario tocó
  /// el botón de confirmar; `false` en cualquier otro caso (cancelar, back).
  static Future<bool> confirm(
    BuildContext context, {
    required String message,
    String? title,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool destructive = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final variant = destructive ? EdumonDialogVariant.error : EdumonDialogVariant.warning;
    final spec = _specFor(variant);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EdumonDialogShell(
        icon: spec.icon,
        iconColor: spec.color,
        iconBg: spec.surface(isDark),
        title: title ?? (destructive ? 'Confirmar eliminación' : 'Confirmar acción'),
        message: message,
        actions: [
          EdumonButton(
            label: cancelLabel,
            variant: EdumonButtonVariant.outline,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          EdumonButton(
            label: confirmLabel,
            variant: destructive ? EdumonButtonVariant.danger : EdumonButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static _DialogSpec _specFor(EdumonDialogVariant variant) {
    switch (variant) {
      case EdumonDialogVariant.error:
        return _DialogSpec(LucideIcons.circleAlert, AppColors.error, AppColors.errorSurface, 'Ocurrió un error', EdumonButtonVariant.danger);
      case EdumonDialogVariant.warning:
        return _DialogSpec(LucideIcons.triangleAlert, AppColors.warning, AppColors.warningSurface, 'Atención', EdumonButtonVariant.warning);
      case EdumonDialogVariant.success:
        return _DialogSpec(LucideIcons.circleCheck, AppColors.success, AppColors.successSurface, '¡Listo!', EdumonButtonVariant.success);
      case EdumonDialogVariant.info:
        return _DialogSpec(
          LucideIcons.info,
          AppColors.primary,
          (isDark) => isDark ? AppColors.primary.withValues(alpha: 0.16) : AppColors.primaryLight,
          'Información',
          EdumonButtonVariant.primary,
        );
    }
  }
}

class _DialogSpec {
  const _DialogSpec(this.icon, this.color, this.surface, this.defaultTitle, this.buttonVariant);
  final IconData icon;
  final Color color;
  final Color Function(bool isDark) surface;
  final String defaultTitle;
  final EdumonButtonVariant buttonVariant;
}

class _EdumonDialogShell extends StatelessWidget {
  const _EdumonDialogShell({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: isDark ? Border.all(color: AppColors.borderNormalDark) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.mutedText(context), height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
