import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/decor/edumon_logo_mark.dart';
import '../../../../core/design_system/decor/edumon_shape_backdrop.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_controller.dart';

/// Login — BLUEPRINT.md FASE 3.1.2.
/// Teléfono (10 dígitos, prefijo fijo +57) + contraseña (mín. 6).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _phoneError = RegExp(r'^\d{10}$').hasMatch(phone)
          ? null
          : 'Ingresa un teléfono válido de 10 dígitos.';
      _passwordError = password.length >= 6
          ? null
          : 'La contraseña debe tener al menos 6 caracteres.';
    });

    if (_phoneError != null || _passwordError != null) return;

    ref
        .read(authControllerProvider.notifier)
        .login(telefono: phone, contrasena: password);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        EdumonDialog.show(context, message: next.errorMessage!);
      }
      // Recién acá, con el login ya confirmado por el backend, se le avisa
      // al motor de autofill que la sesión de campos terminó — es lo que
      // dispara el diálogo nativo "¿Guardar contraseña?" de Android/iOS. Si
      // se llamara en cualquier submit (incluidos los fallidos), ofrecería
      // guardar credenciales incorrectas.
      if (previous?.status != AuthStatus.authenticated &&
          next.status == AuthStatus.authenticated) {
        TextInput.finishAutofillContext();
      }
    });
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.authenticating;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: EdumonShapeBackdrop(
          opacity: 1,
          // Círculos de la galería (assets/img/circulos/), en 3 tamaños: un
          // círculo grande por esquina (1-4), sangrando fuera de pantalla;
          // medianos (5-8) y chicos (9-12) dispersos en la franja libre de
          // arriba (entre las esquinas grandes y la card, que es el único
          // espacio realmente libre — la card es alta y ocupa casi todo el
          // resto, así que cualquier shape puesto "debajo" termina tapado).
          shapes: const [
            ShapeSpec(
              asset: 'circulo1.svg',
              folder: 'circulos',
              size: 160,
              top: -35,
              left: -45,
              rotation: 0.12,
            ),
            ShapeSpec(
              asset: 'circulo2.svg',
              folder: 'circulos',
              size: 170,
              top: -40,
              right: -45,
              rotation: -0.12,
            ),
            ShapeSpec(
              asset: 'circulo3.svg',
              folder: 'circulos',
              size: 150,
              bottom: -35,
              left: -40,
              rotation: -0.15,
            ),
            ShapeSpec(
              asset: 'circulo4.svg',
              folder: 'circulos',
              size: 180,
              bottom: -45,
              right: -40,
              rotation: 0.15,
            ),
            // Medianos, flanqueando el logo sin taparlo.
            ShapeSpec(
              asset: 'circulo5.svg',
              folder: 'circulos',
              size: 52,
              top: 50,
              left: 20,
              rotation: 0.2,
            ),
            ShapeSpec(
              asset: 'circulo6.svg',
              folder: 'circulos',
              size: 56,
              top: 60,
              right: 25,
              rotation: -0.2,
            ),
            ShapeSpec(
              asset: 'circulo7.svg',
              folder: 'circulos',
              size: 48,
              top: 230,
              left: 18,
              rotation: 0.3,
            ),
            ShapeSpec(
              asset: 'circulo8.svg',
              folder: 'circulos',
              size: 50,
              top: 250,
              right: 20,
              rotation: -0.25,
            ),
            // Chicos, más dispersos y cerca del centro.
            ShapeSpec(
              asset: 'circulo9.svg',
              folder: 'circulos',
              size: 30,
              top: 15,
              left: 130,
              rotation: 0.15,
            ),
            ShapeSpec(
              asset: 'circulo10.svg',
              folder: 'circulos',
              size: 28,
              top: 20,
              right: 135,
              rotation: -0.15,
            ),
            ShapeSpec(
              asset: 'circulo11.svg',
              folder: 'circulos',
              size: 32,
              top: 150,
              left: 60,
              rotation: 0.3,
            ),
            ShapeSpec(
              asset: 'circulo12.svg',
              folder: 'circulos',
              size: 30,
              top: 170,
              right: 65,
              rotation: -0.3,
            ),
          ],
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const Center(
                      child: EdumonLogoMark(iconSize: 92, wordmarkWidth: 180),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '¡Bienvenido de vuelta!',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: isDark
                            ? Border.all(color: AppColors.borderNormalDark)
                            : null,
                        boxShadow: isDark ? null : AppShadows.card,
                      ),
                      child: AutofillGroup(
                        // Agrupa los dos campos para que el gestor de
                        // contraseñas del sistema los reconozca como un par
                        // usuario+contraseña y ofrezca guardarlos juntos.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EdumonTextField(
                              controller: _phoneController,
                              label: 'Teléfono',
                              hint: '3001234567',
                              prefixText: '+57 ',
                              leftIcon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              errorText: _phoneError,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                            ),
                            EdumonTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              leftIcon: LucideIcons.lock,
                              obscureText: true,
                              errorText: _passwordError,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              autofillHints: const [AutofillHints.password],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: loading
                                    ? null
                                    : () => context.push('/forgot-password'),
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            EdumonButton(
                              label: 'Ingresar',
                              onPressed: loading ? null : _submit,
                              loading: loading,
                              fullWidth: true,
                              size: EdumonButtonSize.lg,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        '¿No tienes cuenta? Pídele acceso a tu institución.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
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
}
