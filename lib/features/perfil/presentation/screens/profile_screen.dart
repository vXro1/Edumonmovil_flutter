import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Perfil propio — BLUEPRINT.md FASE 3.11.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _cambiarAvatar(BuildContext context, WidgetRef ref) async {
    List<String> avatars;
    try {
      avatars = await ref.read(profileRepositoryProvider).fetchDefaultAvatars();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudieron cargar las fotos.')));
      }
      return;
    }
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Elegí tu foto de perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: avatars.asMap().entries
                    .map(
                      (entry) => EdumonAvatar(
                        radius: 28,
                        imageUrl: entry.value,
                        showBorder: true,
                        semanticLabel: 'Avatar ${entry.key + 1}',
                        onTap: () => Navigator.of(context).pop(entry.value),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    try {
      await ref.read(profileRepositoryProvider).selectDefaultAvatar(selected);
      await ref.read(authControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo actualizar la foto.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeModeProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          EdumonCard(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _cambiarAvatar(context, ref),
                  child: Stack(
                    children: [
                      EdumonAvatar(
                        radius: 40,
                        imageUrl: user.avatarUrl,
                        showBorder: true,
                        fallbackText: user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.pencil, size: 12, color: AppColors.textInverse),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(user.nombreCompleto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _Badge(text: user.rol.label, color: AppColors.primary),
                    _Badge(
                      text: user.estado,
                      color: user.estado == 'activo' ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EdumonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Mis datos', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditProfileSheet(context, ref),
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      label: const Text('Editar'),
                    ),
                  ],
                ),
                if (user.correo != null) _InfoRow(icon: LucideIcons.mail, label: 'Correo', value: user.correo!),
                _InfoRow(icon: LucideIcons.phone, label: 'Teléfono', value: user.telefono),
                // La cédula no es editable desde acá — updateOwnProfile real
                // solo acepta nombre/apellido/correo/telefono, nunca cedula.
                _InfoRow(icon: LucideIcons.idCard, label: 'Cédula', value: user.cedula),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EdumonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apariencia', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(LucideIcons.sun)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(LucideIcons.moon)),
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(LucideIcons.monitor)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) =>
                      ref.read(themeModeProvider.notifier).setThemeMode(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (user.rol == UserRole.administrador || user.rol == UserRole.superAdmin) ...[
            EdumonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Permisos y acceso', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  if (user.permisos.isEmpty)
                    Text('Sin permisos adicionales asignados.', style: TextStyle(color: AppColors.mutedText(context)))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.permisos.map((p) => _Badge(text: p, color: AppColors.accent)).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (user.rol == UserRole.docente) ...[
            EdumonButton(
              label: 'Mis cursos',
              variant: EdumonButtonVariant.outline,
              leftIcon: LucideIcons.bookOpen,
              fullWidth: true,
              onPressed: () => context.push('/cursos'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (user.rol == UserRole.padreTutor) ...[
            EdumonButton(
              label: 'Perfiles de mis hijos',
              variant: EdumonButtonVariant.outline,
              leftIcon: LucideIcons.users,
              fullWidth: true,
              onPressed: () => context.push('/familia/perfiles'),
            ),
            const SizedBox(height: AppSpacing.sm),
            EdumonButton(
              label: 'Cursos de mis hijos',
              variant: EdumonButtonVariant.outline,
              leftIcon: LucideIcons.bookOpen,
              fullWidth: true,
              onPressed: () => context.push('/cursos'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          EdumonButton(
            label: 'Sesiones activas',
            variant: EdumonButtonVariant.outline,
            leftIcon: LucideIcons.shield,
            fullWidth: true,
            onPressed: () => context.push('/sesiones'),
          ),
          const SizedBox(height: AppSpacing.sm),
          EdumonButton(
            label: 'Cambiar contraseña',
            variant: EdumonButtonVariant.outline,
            leftIcon: LucideIcons.keyRound,
            fullWidth: true,
            onPressed: () => _showChangePasswordSheet(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          EdumonButton(
            label: 'Cerrar sesión',
            variant: EdumonButtonVariant.danger,
            leftIcon: LucideIcons.logOut,
            fullWidth: true,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mutedText(context)),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: TextStyle(color: AppColors.mutedText(context))),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Mismo criterio que exige el backend real (changePasswordValidator):
  /// mínimo 6 caracteres, con minúscula, mayúscula y número.
  bool _passwordMeetsRequirements(String pw) {
    return pw.length >= 6 &&
        RegExp(r'[a-z]').hasMatch(pw) &&
        RegExp(r'[A-Z]').hasMatch(pw) &&
        RegExp(r'\d').hasMatch(pw);
  }

  Future<void> _submit() async {
    if (_actualController.text.isEmpty) {
      EdumonDialog.show(context, message: 'Ingresá tu contraseña actual.');
      return;
    }
    if (!_passwordMeetsRequirements(_nuevaController.text)) {
      EdumonDialog.show(
        context,
        message: 'La nueva contraseña debe tener mínimo 6 caracteres, con mayúscula, minúscula y número.',
      );
      return;
    }
    if (_nuevaController.text != _confirmController.text) {
      EdumonDialog.show(context, message: 'Las contraseñas no coinciden.');
      return;
    }
    if (_actualController.text == _nuevaController.text) {
      EdumonDialog.show(context, message: 'La nueva contraseña debe ser distinta a la actual.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(contrasenaActual: _actualController.text, contrasenaNueva: _nuevaController.text);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo cambiar la contraseña.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: _success
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.circleCheck, size: 48, color: AppColors.success),
                const SizedBox(height: AppSpacing.sm),
                const Text('Contraseña actualizada', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                EdumonButton(label: 'Listo', fullWidth: true, onPressed: () => Navigator.of(context).pop()),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                EdumonTextField(controller: _actualController, label: 'Contraseña actual', obscureText: true),
                EdumonTextField(controller: _nuevaController, label: 'Nueva contraseña', obscureText: true),
                EdumonTextField(controller: _confirmController, label: 'Confirmar contraseña', obscureText: true),
                const SizedBox(height: AppSpacing.sm),
                EdumonButton(
                  label: 'Guardar',
                  onPressed: _loading ? null : _submit,
                  loading: _loading,
                  fullWidth: true,
                ),
              ],
            ),
    );
  }
}

/// Editar nombre/apellido/correo/teléfono — disponible para los 4 roles,
/// tanto en el primer ingreso (wizard) como en cualquier momento después
/// (BLUEPRINT.md FASE 3.11 ampliado). La cédula queda afuera a propósito:
/// updateOwnProfile real no la acepta (ver ProfileRemoteDataSource).
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  String? _nombreError, _apellidoError, _correoError, _telefonoError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    _correoController = TextEditingController(text: user?.correo ?? '');
    // El teléfono se guarda con prefijo "+57" — el campo solo edita los 10 dígitos.
    final telefonoDigits = (user?.telefono ?? '').replaceAll(RegExp(r'\D'), '');
    _telefonoController = TextEditingController(
      text: telefonoDigits.length > 10 ? telefonoDigits.substring(telefonoDigits.length - 10) : telefonoDigits,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final correo = _correoController.text.trim();
    final telefono = _telefonoController.text.trim();

    setState(() {
      _nombreError = AppConstants.nombreRegex.hasMatch(nombre) ? null : 'Ingresá un nombre válido.';
      _apellidoError = AppConstants.nombreRegex.hasMatch(apellido) ? null : 'Ingresá un apellido válido.';
      _correoError = correo.isEmpty || AppConstants.emailRegex.hasMatch(correo) ? null : 'Ingresá un correo válido.';
      _telefonoError = AppConstants.phoneRegex.hasMatch(telefono) ? null : 'Ingresá un teléfono válido de 10 dígitos.';
    });
    if ([_nombreError, _apellidoError, _correoError, _telefonoError].any((e) => e != null)) return;

    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            nombre: nombre,
            apellido: apellido,
            correo: correo.isEmpty ? null : correo,
            telefono: '+57$telefono',
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudieron guardar los cambios.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Editar mis datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          EdumonTextField(controller: _nombreController, label: 'Nombre', errorText: _nombreError),
          EdumonTextField(controller: _apellidoController, label: 'Apellido', errorText: _apellidoError),
          EdumonTextField(
            controller: _correoController,
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            errorText: _correoError,
          ),
          EdumonTextField(
            controller: _telefonoController,
            label: 'Teléfono',
            hint: '3001234567',
            prefixText: '+57 ',
            leftIcon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            errorText: _telefonoError,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.sm),
          EdumonButton(
            label: 'Guardar',
            onPressed: _loading ? null : _submit,
            loading: _loading,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
