import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/institucion.dart';
import '../providers/instituciones_providers.dart';

/// Detalle/edición de institución — BLUEPRINT.md FASE 3.3.1.
/// Solo se editan datos de la institución (no NIT ni el admin). El admin se
/// muestra con los datos que el propio backend ya trae poblados
/// (institucionController.js: .populate('adminId', 'nombre apellido correo')),
/// sin necesidad de un fetch adicional a /users/:id.
class InstitucionDetailScreen extends ConsumerStatefulWidget {
  const InstitucionDetailScreen({super.key, required this.institucionId});

  final String institucionId;

  @override
  ConsumerState<InstitucionDetailScreen> createState() => _InstitucionDetailScreenState();
}

class _InstitucionDetailScreenState extends ConsumerState<InstitucionDetailScreen> {
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String? _error;

  void _fillFrom(Institucion institucion) {
    if (_initialized) return;
    _nombreController.text = institucion.nombre;
    _direccionController.text = institucion.direccion ?? '';
    _telefonoController.text = institucion.telefono ?? '';
    _correoController.text = institucion.correo ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(institucionesRepositoryProvider)
          .updateInstitucion(
            id: widget.institucionId,
            nombre: _nombreController.text.trim(),
            direccion: _direccionController.text.trim(),
            telefono: _telefonoController.text.trim(),
            correo: _correoController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is AppException ? e.message : 'No se pudo actualizar la institución.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final institucionesAsync = ref.watch(institucionesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Institución')),
      body: institucionesAsync.when(
        data: (instituciones) {
          final institucion = instituciones.where((i) => i.id == widget.institucionId).firstOrNull;
          if (institucion == null) {
            return Center(child: Text('Institución no encontrada.', style: TextStyle(color: AppColors.mutedText(context))));
          }
          _fillFrom(institucion);

          return SingleChildScrollView(
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
                    child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Builder(
                  builder: (context) {
                    final parts = [
                      if (institucion.nit != null) 'NIT ${institucion.nit}',
                      if (institucion.codigo != null) 'Código ${institucion.codigo}',
                    ];
                    if (parts.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${parts.join(' · ')} (no editable)',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      ),
                    );
                  },
                ),
                EdumonTextField(controller: _nombreController, label: 'Nombre'),
                EdumonTextField(controller: _direccionController, label: 'Dirección'),
                EdumonTextField(controller: _telefonoController, label: 'Teléfono', keyboardType: TextInputType.phone),
                EdumonTextField(controller: _correoController, label: 'Correo', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: AppSpacing.sm),
                EdumonButton(
                  label: 'Guardar cambios',
                  onPressed: _saving ? null : _submit,
                  loading: _saving,
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Administrador', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: AppSpacing.sm),
                if (institucion.admin == null)
                  EdumonCard(child: Text('Sin admin asociado.', style: TextStyle(color: AppColors.mutedText(context))))
                else
                  EdumonCard(
                    child: Row(
                      children: [
                        EdumonAvatar(
                          radius: 20,
                          imageUrl: institucion.admin!.avatarUrl,
                          fallbackText: institucion.admin!.nombre.isNotEmpty ? institucion.admin!.nombre[0].toUpperCase() : '?',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(institucion.admin!.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (institucion.admin!.correo != null)
                                Text(
                                  institucion.admin!.correo!,
                                  style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const LoadingScreenWidget(),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudo cargar la institución.', style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(institucionesListProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
