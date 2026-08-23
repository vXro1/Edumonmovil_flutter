import 'package:flutter/material.dart';
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

/// Recuperar contraseña — BLUEPRINT.md FASE 3.1.3.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _contactController = TextEditingController();

  RecoveryMethod _method = RecoveryMethod.correo;
  String? _error;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  bool _isValid(String contact) {
    return _method == RecoveryMethod.correo
        ? AppConstants.emailRegex.hasMatch(contact)
        : AppConstants.recoveryPhoneRegex.hasMatch(contact);
  }

  Future<void> _submit() async {
    final contact = _contactController.text.trim();
    if (!_isValid(contact)) {
      setState(() {
        _error = _method == RecoveryMethod.correo
            ? 'Ingresa un correo válido.'
            : 'Ingresa un teléfono válido (7 a 15 dígitos).';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).requestPasswordRecovery(method: _method, contact: contact);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo enviar la solicitud.');
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
            ShapeSpec(asset: 'circulo5.svg', folder: 'circulos', size: 96, top: -18, left: -22),
            ShapeSpec(asset: 'circulo6.svg', folder: 'circulos', size: 130, top: -8, right: -28),
            ShapeSpec(asset: 'circulo7.svg', folder: 'circulos', size: 140, bottom: -28, left: -20),
            ShapeSpec(asset: 'circulo8.svg', folder: 'circulos', size: 96, bottom: -16, right: -14),
          ],
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: EdumonLogoMark(iconSize: 60, showWordmark: false)),
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
                        child: _sent
                            ? _SentState(contact: _contactController.text.trim(), method: _method)
                            : _form(isDark),
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
        Text('Recuperar contraseña', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Elegí cómo querés recibir el código de recuperación.',
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        SegmentedButton<RecoveryMethod>(
          segments: const [
            ButtonSegment(value: RecoveryMethod.correo, label: Text('Correo'), icon: Icon(LucideIcons.mail)),
            ButtonSegment(
              value: RecoveryMethod.telefono,
              label: Text('WhatsApp'),
              icon: Icon(LucideIcons.messageCircle),
            ),
          ],
          selected: {_method},
          onSelectionChanged: (selection) => setState(() {
            _method = selection.first;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        EdumonTextField(
          controller: _contactController,
          label: _method == RecoveryMethod.correo ? 'Correo' : 'Teléfono',
          // Antes: '+573001234567' — inconsistente con login(), donde el
          // usuario NO tipea el +57 (se le antepone en el datasource). Ahora
          // el hint refleja el mismo formato: solo el número local.
          hint: _method == RecoveryMethod.correo ? 'tu@correo.com' : '3001234567',
          leftIcon: _method == RecoveryMethod.correo ? LucideIcons.mail : LucideIcons.phone,
          keyboardType: _method == RecoveryMethod.correo ? TextInputType.emailAddress : TextInputType.phone,
          errorText: _error,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.sm),
        EdumonButton(
          label: 'Enviar código',
          onPressed: _loading ? null : _submit,
          loading: _loading,
          fullWidth: true,
          size: EdumonButtonSize.lg,
          variant: EdumonButtonVariant.accent,
        ),
      ],
    );
  }
}

class _SentState extends StatelessWidget {
  const _SentState({required this.contact, required this.method});

  final String contact;
  final RecoveryMethod method;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey('sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.mailCheck, size: 56, color: AppColors.success),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Código enviado',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          method == RecoveryMethod.correo
              ? 'Revisá tu correo ($contact) y buscá el código de recuperación.'
              : 'Revisá los mensajes de $contact y buscá el código de recuperación.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        EdumonButton(
          label: 'Ingresar código',
          fullWidth: true,
          size: EdumonButtonSize.lg,
          variant: EdumonButtonVariant.accent,
          onPressed: () => context.push('/reset-password', extra: {'contact': contact, 'method': method}),
        ),
      ],
    );
  }
}