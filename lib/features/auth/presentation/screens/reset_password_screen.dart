import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/decor/edumon_logo_mark.dart';
import '../../../../core/design_system/decor/edumon_shape_backdrop.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';

/// Introducir código + nueva contraseña — BLUEPRINT.md FASE 3.1.4.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.contact, required this.method});

  final String contact;
  final RecoveryMethod method;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _codeError;
  String? _passwordError;
  String? _confirmError;
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      _codeError = AppConstants.recoveryCodeRegex.hasMatch(code) ? null : 'El código debe tener entre 4 y 8 dígitos.';
      _passwordError = password.length >= 6 ? null : 'La contraseña debe tener al menos 6 caracteres.';
      _confirmError = confirm == password ? null : 'Las contraseñas no coinciden.';
    });

    if (_codeError != null || _passwordError != null || _confirmError != null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(method: widget.method, contact: widget.contact, codigo: code, nuevaContrasena: password);
      if (!mounted) return;
      setState(() => _success = true);
    } catch (e) {
      if (!mounted) return;
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo restablecer la contraseña.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: EdumonShapeBackdrop(
          shapes: const [
            ShapeSpec(asset: 'circulo9.svg', folder: 'circulos', size: 96, top: -18, left: -22),
            ShapeSpec(asset: 'circulo10.svg', folder: 'circulos', size: 130, top: -8, right: -28),
            ShapeSpec(asset: 'circulo11.svg', folder: 'circulos', size: 140, bottom: -28, left: -20),
            ShapeSpec(asset: 'circulo12.svg', folder: 'circulos', size: 96, bottom: -16, right: -14),
          ],
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: EdumonLogoMark(width: 150)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: isDark ? Border.all(color: AppColors.borderNormalDark) : null,
                        boxShadow: isDark ? null : AppShadows.card,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _success ? _successState(isDark) : _form(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(bool isDark) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nueva contraseña', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ingresá el código que enviamos a ${widget.contact}.',
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        EdumonTextField(
          controller: _codeController,
          label: 'Código',
          hint: '123456',
          leftIcon: LucideIcons.keyRound,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
          errorText: _codeError,
        ),
        EdumonTextField(
          controller: _passwordController,
          label: 'Nueva contraseña',
          leftIcon: LucideIcons.lock,
          obscureText: true,
          errorText: _passwordError,
        ),
        EdumonTextField(
          controller: _confirmController,
          label: 'Confirmar contraseña',
          leftIcon: LucideIcons.lock,
          obscureText: true,
          errorText: _confirmError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.sm),
        EdumonButton(
          label: 'Restablecer contraseña',
          onPressed: _loading ? null : _submit,
          loading: _loading,
          fullWidth: true,
          size: EdumonButtonSize.lg,
          variant: EdumonButtonVariant.accent,
        ),
      ],
    );
  }

  Widget _successState(bool isDark) {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.circleCheck, size: 56, color: AppColors.success),
        const SizedBox(height: AppSpacing.md),
        Text('¡Contraseña actualizada!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ya podés iniciar sesión con tu nueva contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        EdumonButton(
          label: 'Ir a iniciar sesión',
          fullWidth: true,
          size: EdumonButtonSize.lg,
          variant: EdumonButtonVariant.accent,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
