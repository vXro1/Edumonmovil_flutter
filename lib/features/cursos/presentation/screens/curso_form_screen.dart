import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/dialogs/edumon_color_picker.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../usuarios/presentation/providers/usuarios_providers.dart';
import '../providers/cursos_providers.dart';

/// Crear/editar curso — BLUEPRINT.md FASE 3.4.1.
/// [cursoId] null = crear; con valor = editar.
class CursoFormScreen extends ConsumerStatefulWidget {
  const CursoFormScreen({super.key, this.cursoId});

  final String? cursoId;

  @override
  ConsumerState<CursoFormScreen> createState() => _CursoFormScreenState();
}

class _CursoFormScreenState extends ConsumerState<CursoFormScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _colorController = TextEditingController();

  String? _docenteId;
  String? _docenteNombreActual;
  Uint8List? _portadaBytes;
  String? _portadaFilename;
  String? _portadaUrlExistente;

  bool _loadingCurso = false;
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isEditing => widget.cursoId != null;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    if (user?.rol == UserRole.docente) _docenteId = user!.id;
    if (_isEditing) _loadCurso();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadCurso() async {
    setState(() => _loadingCurso = true);
    try {
      final curso = await ref.read(cursosRepositoryProvider).fetchCursoById(widget.cursoId!);
      if (!mounted) return;
      _nombreController.text = curso.nombre;
      _descripcionController.text = curso.descripcion ?? '';
      _colorController.text = curso.color ?? '';
      setState(() {
        _docenteId = curso.docenteId;
        _docenteNombreActual = curso.docente?.nombreCompleto;
        _portadaUrlExistente = curso.imagenUrl;
        _loadingCurso = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCurso = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo cargar el curso.');
    }
  }

  Future<void> _pickPortada() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _portadaBytes = bytes;
      _portadaFilename = picked.name;
    });
  }

  Future<void> _pickColor() async {
    final current = colorFromHex(_colorController.text.trim());
    final picked = await showEdumonColorPicker(context, initialColor: current);
    if (picked == null) return;
    setState(() => _colorController.text = colorToHex(picked));
  }

  Future<void> _submit() async {
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final color = _colorController.text.trim();

    final errors = <String, String>{};
    if (nombre.isEmpty) errors['nombre'] = 'Ingresá el nombre del curso.';
    if (!_isEditing && _docenteId == null) errors['docenteId'] = 'Seleccioná un docente.';
    if (color.isNotEmpty && !AppConstants.hexColorRegex.hasMatch(color)) {
      errors['color'] = 'Usá un color hex válido, ej. #4F46E5.';
    }

    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(cursosRepositoryProvider);
      if (_isEditing) {
        // docenteId ya no se manda al editar — cursoController.js real lo
        // ignora, y mostrar un dropdown editable acá era engañoso (ver build()).
        await repo.updateCurso(
          id: widget.cursoId!,
          nombre: nombre,
          descripcion: descripcion,
          color: color.isEmpty ? null : color,
          fotoPortadaBytes: _portadaBytes,
          fotoPortadaFilename: _portadaFilename,
        );
      } else {
        await repo.createCurso(
          nombre: nombre,
          descripcion: descripcion,
          docenteId: _docenteId!,
          color: color.isEmpty ? null : color,
          fotoPortadaBytes: _portadaBytes,
          fotoPortadaFilename: _portadaFilename,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e is AppException && e.fieldErrors != null) _fieldErrors = e.fieldErrors!;
      });
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo guardar el curso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(authControllerProvider).user?.rol;
    final isDocente = currentRole == UserRole.docente;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar curso' : 'Nuevo curso')),
      body: _loadingCurso
          ? const LoadingScreenWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickPortada,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? AppColors.surface2Dark : AppColors.surface2,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          image: _portadaBytes != null
                              ? DecorationImage(image: MemoryImage(_portadaBytes!), fit: BoxFit.cover)
                              : (_portadaUrlExistente != null
                                    ? DecorationImage(image: NetworkImage(_portadaUrlExistente!), fit: BoxFit.cover)
                                    : null),
                        ),
                        child: (_portadaBytes == null && _portadaUrlExistente == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.image, color: AppColors.subtleText(context), size: 32),
                                  const SizedBox(height: 4),
                                  Text('Toca para elegir portada', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EdumonTextField(controller: _nombreController, label: 'Nombre del curso', errorText: _fieldErrors['nombre']),
                  EdumonTextField(controller: _descripcionController, label: 'Descripción (opcional)'),
                  const Text('Color del curso (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: _pickColor,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _fieldErrors['color'] != null
                              ? AppColors.error
                              : (context.isDarkMode ? AppColors.borderNormalDark : AppColors.borderNormal),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorFromHex(_colorController.text) ?? AppColors.surface2,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.isDarkMode ? Colors.white24 : Colors.black12),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _colorController.text.isEmpty
                                  ? 'Elegí un color para identificar el curso'
                                  : _colorController.text,
                              style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                            ),
                          ),
                          Icon(LucideIcons.palette, size: 18, color: AppColors.mutedText(context)),
                        ],
                      ),
                    ),
                  ),
                  if (_fieldErrors['color'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_fieldErrors['color']!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  // El docente titular ya no se puede reasignar editando un
                  // curso existente — cursoController.js real ignora docenteId
                  // en el update. Se muestra solo informativo al editar.
                  if (_isEditing)
                    Text(
                      'Docente titular: ${_docenteNombreActual ?? 'sin asignar'}',
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                    )
                  else if (isDocente)
                    Text('Vas a ser el docente titular de este curso.', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12))
                  else ...[
                    const Text('Docente', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, _) {
                        return FutureBuilder(
                          future: ref.read(usuariosRepositoryProvider).fetchUsuarios(page: 1, limit: 100, rol: UserRole.docente),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator();
                            final docentes = snapshot.data!.items;
                            return DropdownButtonFormField<String>(
                              initialValue: _docenteId,
                              isExpanded: true,
                              items: docentes
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d.id,
                                      child: Text(d.nombreCompleto, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() => _docenteId = value),
                              hint: const Text('Seleccioná un docente'),
                            );
                          },
                        );
                      },
                    ),
                    if (_fieldErrors['docenteId'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_fieldErrors['docenteId']!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  EdumonButton(
                    label: _isEditing ? 'Guardar cambios' : 'Crear curso',
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
