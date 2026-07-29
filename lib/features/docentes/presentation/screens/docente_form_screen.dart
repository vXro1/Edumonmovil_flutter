import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/docentes_providers.dart';

/// Crear docente individual — BLUEPRINT.md FASE 3.3.3.
class DocenteFormScreen extends ConsumerStatefulWidget {
  const DocenteFormScreen({super.key});

  @override
  ConsumerState<DocenteFormScreen> createState() => _DocenteFormScreenState();
}

class _DocenteFormScreenState extends ConsumerState<DocenteFormScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  Map<String, String> _fieldErrors = const {};
  bool _saving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final cedula = _cedulaController.text.trim();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim();

    final errors = <String, String>{};
    if (nombre.isEmpty) errors['nombre'] = 'Ingresá el nombre.';
    if (apellido.isEmpty) errors['apellido'] = 'Ingresá el apellido.';
    if (!AppConstants.cedulaRegex.hasMatch(cedula)) errors['cedula'] = 'La cédula debe tener entre 6 y 10 dígitos.';
    if (!AppConstants.phoneRegex.hasMatch(telefono)) errors['telefono'] = 'El teléfono debe tener 10 dígitos.';
    if (correo.isNotEmpty && !AppConstants.emailRegex.hasMatch(correo)) errors['correo'] = 'Ingresá un correo válido.';

    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(docentesRepositoryProvider)
          .createDocente(
            nombre: nombre,
            apellido: apellido,
            cedula: cedula,
            telefono: telefono,
            correo: correo.isEmpty ? null : correo,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e is AppException && e.fieldErrors != null) _fieldErrors = e.fieldErrors!;
      });
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo crear el docente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo docente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EdumonTextField(controller: _nombreController, label: 'Nombre', errorText: _fieldErrors['nombre']),
            EdumonTextField(controller: _apellidoController, label: 'Apellido', errorText: _fieldErrors['apellido']),
            EdumonTextField(
              controller: _cedulaController,
              label: 'Cédula',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              errorText: _fieldErrors['cedula'],
            ),
            EdumonTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              errorText: _fieldErrors['telefono'],
            ),
            EdumonTextField(
              controller: _correoController,
              label: 'Correo (opcional)',
              keyboardType: TextInputType.emailAddress,
              errorText: _fieldErrors['correo'],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La contraseña inicial del docente será su cédula. Si no cargás un '
              'correo, se genera uno temporal no funcional — vas a tener que '
              'compartirle la contraseña por otro medio.',
              style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.lg),
            EdumonButton(
              label: 'Crear docente',
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
