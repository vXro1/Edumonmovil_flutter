import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/instituciones_providers.dart';

/// Crear institución + admin inicial en un solo formulario — BLUEPRINT.md FASE 3.3.1.
class InstitucionFormScreen extends ConsumerStatefulWidget {
  const InstitucionFormScreen({super.key});

  @override
  ConsumerState<InstitucionFormScreen> createState() => _InstitucionFormScreenState();
}

class _InstitucionFormScreenState extends ConsumerState<InstitucionFormScreen> {
  final _nombreController = TextEditingController();
  final _nitController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  final _adminNombreController = TextEditingController();
  final _adminApellidoController = TextEditingController();
  final _adminCedulaController = TextEditingController();
  final _adminCorreoController = TextEditingController();
  final _adminTelefonoController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _nombreController,
      _nitController,
      _direccionController,
      _telefonoController,
      _correoController,
      _adminNombreController,
      _adminApellidoController,
      _adminCedulaController,
      _adminCorreoController,
      _adminTelefonoController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nombreController.text.trim().isEmpty ||
        _nitController.text.trim().isEmpty ||
        _adminNombreController.text.trim().isEmpty ||
        _adminApellidoController.text.trim().isEmpty ||
        !AppConstants.cedulaRegex.hasMatch(_adminCedulaController.text.trim())) {
      setState(() => _error = 'Completá los campos obligatorios (nombre, NIT y datos del admin).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(institucionesRepositoryProvider)
          .createInstitucion(
            nombre: _nombreController.text.trim(),
            nit: _nitController.text.trim(),
            direccion: _direccionController.text.trim(),
            telefono: _telefonoController.text.trim(),
            correo: _correoController.text.trim(),
            adminNombre: _adminNombreController.text.trim(),
            adminApellido: _adminApellidoController.text.trim(),
            adminCedula: _adminCedulaController.text.trim(),
            adminCorreo: _adminCorreoController.text.trim(),
            adminTelefono: _adminTelefonoController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is AppException ? e.message : 'No se pudo crear la institución.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva institución')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface(context.isDarkMode),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const Text('Datos de la institución', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            EdumonTextField(controller: _nombreController, label: 'Nombre'),
            EdumonTextField(controller: _nitController, label: 'NIT'),
            EdumonTextField(controller: _direccionController, label: 'Dirección'),
            EdumonTextField(controller: _telefonoController, label: 'Teléfono', keyboardType: TextInputType.phone),
            EdumonTextField(controller: _correoController, label: 'Correo', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.lg),
            const Text('Administrador inicial', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'La contraseña inicial del admin será su cédula.',
              style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            EdumonTextField(controller: _adminNombreController, label: 'Nombre'),
            EdumonTextField(controller: _adminApellidoController, label: 'Apellido'),
            EdumonTextField(controller: _adminCedulaController, label: 'Cédula', keyboardType: TextInputType.number),
            EdumonTextField(controller: _adminCorreoController, label: 'Correo', keyboardType: TextInputType.emailAddress),
            EdumonTextField(controller: _adminTelefonoController, label: 'Teléfono', keyboardType: TextInputType.phone),
            const SizedBox(height: AppSpacing.lg),
            EdumonButton(
              label: 'Crear institución',
              onPressed: _saving ? null : _submit,
              loading: _saving,
              fullWidth: true,
              size: EdumonButtonSize.lg,
            ),
          ],
        ),
      ),
    );
  }
}
