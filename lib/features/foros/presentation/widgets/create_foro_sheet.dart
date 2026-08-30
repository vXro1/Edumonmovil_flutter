import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/foro.dart';
import '../../domain/repositories/foros_repository.dart';
import '../providers/foros_providers.dart';

const _maxArchivos = 5;

/// Bottom sheet "Nuevo foro" / "Editar foro" — BLUEPRINT.md FASE 3.4.8 /
/// 3.8.3 (también se crea desde el sidebar del ForumScreen canónico).
/// Devuelve true si se creó/guardó. Permite adjuntar hasta 5 archivos
/// (imagen/video/PDF) al CREAR, igual que el compositor de mensajes de foro
/// — el backend ya acepta `archivos` en POST /foros vía multipart/form-data
/// (foroController.crearForo). actualizarForo real NO soporta reemplazar
/// archivos ni el estado (eso va por toggleEstadoForo aparte), así que en
/// modo edición solo se editan título/descripción/público.
Future<bool?> showCreateForoSheet(BuildContext context, WidgetRef ref, String cursoId, {Foro? existing}) {
  final isEditing = existing != null;
  final tituloController = TextEditingController(text: existing?.titulo);
  final descripcionController = TextEditingController(text: existing?.descripcion);
  String? tituloError, descripcionError;
  final archivosNuevos = <PlatformFile>[];
  bool saving = false;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
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
              Text(isEditing ? 'Editar foro' : 'Nuevo foro', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              EdumonTextField(controller: tituloController, label: 'Título', errorText: tituloError),
              EdumonTextField(
                controller: descripcionController,
                label: 'Descripción',
                maxLines: 4,
                minLines: 3,
                errorText: descripcionError,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!isEditing) ...[
                if (archivosNuevos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: archivosNuevos
                          .map(
                            (f) => Chip(
                              label: Text(f.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                              onDeleted: () => setSheetState(() => archivosNuevos.remove(f)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: archivosNuevos.length >= _maxArchivos
                      ? null
                      : () async {
                          final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
                          if (result == null) return;
                          setSheetState(() {
                            final espacio = _maxArchivos - archivosNuevos.length;
                            archivosNuevos.addAll(result.files.where((f) => f.bytes != null).take(espacio < 0 ? 0 : espacio));
                          });
                        },
                  icon: const Icon(LucideIcons.paperclip, size: 16),
                  label: Text(
                    archivosNuevos.length >= _maxArchivos ? 'Máximo $_maxArchivos archivos' : 'Adjuntar archivo',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              EdumonButton(
                label: isEditing ? 'Guardar cambios' : 'Crear foro',
                fullWidth: true,
                loading: saving,
                onPressed: saving
                    ? null
                    : () async {
                        final titulo = tituloController.text.trim();
                        final descripcion = descripcionController.text.trim();
                        setSheetState(() {
                          tituloError = titulo.length >= 5 && titulo.length <= 200
                              ? null
                              : 'El título debe tener entre 5 y 200 caracteres.';
                          descripcionError = descripcion.length >= 10 && descripcion.length <= 2000
                              ? null
                              : 'La descripción debe tener entre 10 y 2000 caracteres.';
                        });
                        if (tituloError != null || descripcionError != null) return;
                        setSheetState(() => saving = true);
                        try {
                          final repo = ref.read(forosRepositoryProvider);
                          if (isEditing) {
                            await repo.updateForo(id: existing.id, titulo: titulo, descripcion: descripcion);
                          } else {
                            final archivos = archivosNuevos
                                .map((f) => ArchivoUpload(bytes: f.bytes!, filename: f.name))
                                .toList();
                            await repo.createForo(
                              titulo: titulo,
                              descripcion: descripcion,
                              cursoId: cursoId,
                              archivos: archivos.isEmpty ? null : archivos,
                            );
                          }
                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          setSheetState(() => saving = false);
                          if (context.mounted) {
                            EdumonDialog.show(
                              context,
                              message: e is AppException ? e.message : 'No se pudo guardar el foro.',
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        );
      },
    ),
  );
}
