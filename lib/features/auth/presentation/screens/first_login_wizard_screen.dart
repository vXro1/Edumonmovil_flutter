import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/decor/edumon_logo_mark.dart';
import '../../../../core/design_system/decor/edumon_shape_backdrop.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_providers.dart';

/// Wizard de primer login (4 pasos) — BLUEPRINT.md FASE 3.1.4.
/// ⚠️ En la web esta ruta estaba desconectada (bug) — acá está implementada
/// completa y funcional. Bloquea el botón "atrás" del sistema mientras el
/// wizard esté incompleto, salvo para retroceder un paso dentro del wizard.
///
/// Orden: Foto → Datos personales (nombre/apellido/teléfono/correo) →
/// Contraseña → Confirmación.
class FirstLoginWizardScreen extends ConsumerStatefulWidget {
  const FirstLoginWizardScreen({super.key});

  @override
  ConsumerState<FirstLoginWizardScreen> createState() => _FirstLoginWizardScreenState();
}

enum _WizardStep { foto, datos, seguridad, confirmacion }

class _FirstLoginWizardScreenState extends ConsumerState<FirstLoginWizardScreen> {
  _WizardStep _step = _WizardStep.foto;

  // Paso 1 — foto (solo avatares predeterminados del sistema, sin subida propia).
  List<String> _avatars = const [];
  bool _avatarsLoading = true;
  String? _avatarsError;
  String? _selectedAvatarUrl;
  String? _originalAvatarUrl;

  // Paso 2 — datos personales + teléfono + correo.
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  String? _nombreError, _apellidoError, _telefonoError, _correoError;

  // Paso 3 — contraseña (obligatorio, va al final): primero confirma la
  // actual (la temporal con la que inició sesión), después elige la nueva.
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _currentPasswordError, _passwordError, _confirmError;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    // El teléfono se guarda con prefijo "+57" — el campo solo edita los 10 dígitos.
    final telefonoDigits = (user?.telefono ?? '').replaceAll(RegExp(r'\D'), '');
    _telefonoController = TextEditingController(
      text: telefonoDigits.length >= 10 ? telefonoDigits.substring(telefonoDigits.length - 10) : telefonoDigits,
    );
    _correoController = TextEditingController(text: user?.correo ?? '');
    _originalAvatarUrl = user?.avatarUrl;
    _selectedAvatarUrl = user?.avatarUrl;
    _loadAvatars();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_step == _WizardStep.foto) return;
    setState(() => _step = _WizardStep.values[_step.index - 1]);
  }

  Future<void> _loadAvatars() async {
    setState(() {
      _avatarsLoading = true;
      _avatarsError = null;
    });
    try {
      final avatars = await ref.read(profileRepositoryProvider).fetchDefaultAvatars();
      if (!mounted) return;
      setState(() {
        _avatars = avatars;
        _avatarsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avatarsLoading = false;
        _avatarsError = e is AppException ? e.message : 'No se pudieron cargar las fotos disponibles.';
      });
    }
  }

  int _passwordStrength(String pw) {
    var score = 0;
    if (pw.length >= 6) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[a-z]').hasMatch(pw)) score++;
    if (RegExp(r'\d').hasMatch(pw)) score++;
    return score;
  }

  Future<void> _submitSecurityStep() async {
    final currentPassword = _currentPasswordController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      _currentPasswordError = currentPassword.isNotEmpty ? null : 'Ingresá tu contraseña actual.';
      _passwordError = _passwordStrength(password) == 4
          ? null
          : 'Mínimo 6 caracteres, con mayúscula, minúscula y número.';
      _confirmError = confirm == password ? null : 'Las contraseñas no coinciden.';
    });
    if (_currentPasswordError != null || _passwordError != null || _confirmError != null) return;

    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            contrasenaActual: currentPassword,
            contrasenaNueva: password,
          );
      if (!mounted) return;
      setState(() {
        _step = _WizardStep.confirmacion;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo actualizar la contraseña.');
    }
  }

  Future<void> _submitPhotoStep() async {
    if (_selectedAvatarUrl == null) {
      EdumonDialog.show(context, message: 'Elegí una foto de perfil para continuar.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_selectedAvatarUrl != _originalAvatarUrl) {
        await ref.read(profileRepositoryProvider).selectDefaultAvatar(_selectedAvatarUrl!);
      }
      if (!mounted) return;
      setState(() {
        _step = _WizardStep.datos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo guardar la foto.');
    }
  }

  Future<void> _submitDataStep() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final telefonoDigits = _telefonoController.text.trim();
    final correo = _correoController.text.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    setState(() {
      _nombreError = nombre.isNotEmpty ? null : 'Ingresá tu nombre.';
      _apellidoError = apellido.isNotEmpty ? null : 'Ingresá tu apellido.';
      _telefonoError = RegExp(r'^\d{10}$').hasMatch(telefonoDigits) ? null : 'Ingresá un teléfono válido de 10 dígitos.';
      _correoError = emailRegex.hasMatch(correo) ? null : 'Ingresá un correo válido.';
    });
    if ([_nombreError, _apellidoError, _telefonoError, _correoError].any((e) => e != null)) return;

    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            nombre: nombre,
            apellido: apellido,
            correo: correo,
            telefono: '+57$telefonoDigits',
          );
      if (!mounted) return;
      setState(() {
        _step = _WizardStep.seguridad;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudieron guardar los cambios.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: EdumonShapeBackdrop(
            shapes: const [
              ShapeSpec(asset: 'circulo1.svg', folder: 'circulos', size: 96, top: -18, left: -22),
              ShapeSpec(asset: 'circulo2.svg', folder: 'circulos', size: 130, top: -8, right: -28),
              ShapeSpec(asset: 'circulo3.svg', folder: 'circulos', size: 140, bottom: -28, left: -20),
              ShapeSpec(asset: 'circulo4.svg', folder: 'circulos', size: 96, bottom: -16, right: -14),
            ],
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: _step != _WizardStep.foto && _step != _WizardStep.confirmacion
                          ? IconButton(
                              icon: const Icon(LucideIcons.arrowLeft),
                              tooltip: 'Atrás',
                              onPressed: _loading ? null : _goBack,
                            )
                          : null,
                    ),
                    Expanded(child: _StepIndicator(step: _step.index)),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: isDark ? Border.all(color: AppColors.borderNormalDark) : null,
                          boxShadow: isDark ? null : AppShadows.card,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: switch (_step) {
                            _WizardStep.foto => _photoStep(isDark),
                            _WizardStep.datos => _dataStep(isDark),
                            _WizardStep.seguridad => _securityStep(isDark),
                            _WizardStep.confirmacion => _confirmationStep(isDark),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _securityStep(bool isDark) {
    final strength = _passwordStrength(_passwordController.text);
    return StatefulBuilder(
      key: const ValueKey('seguridad'),
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Por último, tu contraseña', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Confirmá tu contraseña actual y elegí una nueva para terminar.',
              style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            EdumonTextField(
              controller: _currentPasswordController,
              label: 'Contraseña actual',
              obscureText: true,
              errorText: _currentPasswordError,
            ),
            const SizedBox(height: AppSpacing.sm),
            EdumonTextField(
              controller: _passwordController,
              label: 'Nueva contraseña',
              obscureText: true,
              errorText: _passwordError,
              onChanged: (_) => setLocalState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: strength / 4,
                minHeight: 6,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation(
                  switch (strength) {
                    <= 1 => AppColors.error,
                    <= 2 => AppColors.warning,
                    <= 3 => AppColors.accent,
                    _ => AppColors.success,
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            EdumonTextField(
              controller: _confirmController,
              label: 'Confirmar contraseña',
              obscureText: true,
              errorText: _confirmError,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),
            EdumonButton(
              label: 'Siguiente',
              onPressed: _loading ? null : _submitSecurityStep,
              loading: _loading,
              fullWidth: true,
              size: EdumonButtonSize.lg,
              rightIcon: LucideIcons.arrowRight,
              // Morado = color hero de Login/Landing/marca (paleta v2) —
              // el wizard de primer ingreso es parte de ese flujo.
              variant: EdumonButtonVariant.accent,
            ),
          ],
        );
      },
    );
  }

  Widget _photoStep(bool isDark) {
    return Column(
      key: const ValueKey('photo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: EdumonLogoMark(width: 140)),
        const SizedBox(height: AppSpacing.sm),
        Text('¡Bienvenido a EDUMON!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Para empezar, elegí tu foto de perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: EdumonAvatar(
            radius: 48,
            imageUrl: _selectedAvatarUrl,
            showBorder: true,
            backgroundColor: isDark ? AppColors.surface2Dark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_avatarsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_avatarsError != null)
          Column(
            children: [
              Text(
                _avatarsError!,
                style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _loadAvatars, child: const Text('Reintentar')),
            ],
          )
        else if (_avatars.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: _avatars.asMap().entries.map((entry) {
              final url = entry.value;
              final selected = _selectedAvatarUrl == url;
              return EdumonAvatar(
                radius: 28,
                imageUrl: url,
                backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surface2,
                showBorder: true,
                selected: selected,
                semanticLabel: 'Avatar ${entry.key + 1}',
                onTap: () => setState(() => _selectedAvatarUrl = url),
              );
            }).toList(),
          ),
        const SizedBox(height: AppSpacing.md),
        EdumonButton(
          label: 'Siguiente',
          onPressed: _loading ? null : _submitPhotoStep,
          loading: _loading,
          fullWidth: true,
          size: EdumonButtonSize.lg,
          rightIcon: LucideIcons.arrowRight,
          variant: EdumonButtonVariant.accent,
        ),
      ],
    );
  }

  Widget _dataStep(bool isDark) {
    return Column(
      key: const ValueKey('data'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tus datos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Confirmá o actualizá tu información de contacto.',
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        EdumonTextField(controller: _nombreController, label: 'Nombre', errorText: _nombreError),
        EdumonTextField(controller: _apellidoController, label: 'Apellido', errorText: _apellidoError),
        EdumonTextField(
          controller: _telefonoController,
          label: 'Teléfono',
          hint: '3001234567',
          prefixText: '+57 ',
          leftIcon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          errorText: _telefonoError,
        ),
        EdumonTextField(
          controller: _correoController,
          label: 'Correo',
          keyboardType: TextInputType.emailAddress,
          errorText: _correoError,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.md),
        EdumonButton(
          label: 'Siguiente',
          onPressed: _loading ? null : _submitDataStep,
          loading: _loading,
          fullWidth: true,
          size: EdumonButtonSize.lg,
          rightIcon: LucideIcons.arrowRight,
          variant: EdumonButtonVariant.accent,
        ),
      ],
    );
  }

  Widget _confirmationStep(bool isDark) {
    return Column(
      key: const ValueKey('confirmation'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.partyPopper, size: 56, color: AppColors.success),
        const SizedBox(height: AppSpacing.md),
        Text('¡Todo listo!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ya configuraste tu cuenta. Vamos a tu panel.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        EdumonButton(
          label: 'Ir a mi cuenta',
          fullWidth: true,
          size: EdumonButtonSize.lg,
          variant: EdumonButtonVariant.accent,
          onPressed: () => ref.read(authControllerProvider.notifier).completeFirstLogin(),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == step ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : (isDark ? AppColors.borderNormalDark : AppColors.neutral200),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
