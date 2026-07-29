import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/modulo.dart';
import '../providers/cursos_providers.dart';

/// Tab Módulos — BLUEPRINT.md FASE 3.4.3.
/// El import CSV es 100% client-side (no hay endpoint masivo de módulos en
/// el backend): se parsea el archivo acá y se itera un POST /modulos por fila.
class ModulosTab extends ConsumerStatefulWidget {
  const ModulosTab({super.key, required this.cursoId, required this.canManage});

  final String cursoId;
  final bool canManage;

  @override
  ConsumerState<ModulosTab> createState() => _ModulosTabState();
}

class _ModulosTabState extends ConsumerState<ModulosTab> {
  List<Modulo> _items = const [];
  bool _loading = true;
  bool _importing = false;
  bool _showInactive = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(modulosRepositoryProvider)
          .fetchModulos(widget.cursoId, incluirInactivos: _showInactive);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los módulos.';
      });
    }
  }

  Future<void> _openForm({Modulo? existing}) async {
    final tituloController = TextEditingController(text: existing?.titulo);
    final descripcionController = TextEditingController(text: existing?.descripcion);
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
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
                Text(existing == null ? 'Nuevo módulo' : 'Editar módulo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                EdumonTextField(controller: tituloController, label: 'Título'),
                EdumonTextField(controller: descripcionController, label: 'Descripción (opcional)'),
                const SizedBox(height: AppSpacing.sm),
                EdumonButton(
                  label: 'Guardar',
                  fullWidth: true,
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final titulo = tituloController.text.trim();
                          if (titulo.isEmpty) {
                            EdumonDialog.show(context, message: 'Ingresá un título.');
                            return;
                          }
                          setSheetState(() => saving = true);
                          try {
                            final repo = ref.read(modulosRepositoryProvider);
                            if (existing == null) {
                              await repo.createModulo(
                                cursoId: widget.cursoId,
                                titulo: titulo,
                                descripcion: descripcionController.text.trim(),
                              );
                            } else {
                              await repo.updateModulo(
                                id: existing.id,
                                titulo: titulo,
                                descripcion: descripcionController.text.trim(),
                              );
                            }
                            if (context.mounted) Navigator.of(context).pop(true);
                          } catch (e) {
                            setSheetState(() => saving = false);
                            if (context.mounted) {
                              EdumonDialog.show(
                                context,
                                message: e is AppException ? e.message : 'No se pudo guardar el módulo.',
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

    if (saved == true) _load();
  }

  Future<void> _delete(Modulo modulo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ocultar módulo'),
        // deleteModulo real hace soft-delete (estado: 'inactivo'), no borra —
        // queda oculto de la lista pero es recuperable desde el backend.
        content: Text('¿Ocultar "${modulo.titulo}"? Vas a dejar de verlo en la lista, pero se puede restaurar después.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ocultar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(modulosRepositoryProvider).deleteModulo(modulo.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo eliminar.')));
    }
  }

  Future<void> _restore(Modulo modulo) async {
    try {
      await ref.read(modulosRepositoryProvider).restoreModulo(modulo.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo restaurar.')));
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _importing = true);
    var exitosos = 0;
    var fallidos = 0;
    try {
      final lines = utf8.decode(file.bytes!).split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
      final repo = ref.read(modulosRepositoryProvider);
      for (final line in lines) {
        final cols = line.split(',').map((c) => c.trim().replaceAll('"', '')).toList();
        if (cols.isEmpty || cols.first.toLowerCase() == 'titulo') continue; // salta encabezado
        final titulo = cols[0];
        final descripcion = cols.length > 1 ? cols[1] : null;
        if (titulo.isEmpty) continue;
        try {
          await repo.createModulo(cursoId: widget.cursoId, titulo: titulo, descripcion: descripcion);
          exitosos++;
        } catch (_) {
          fallidos++;
        }
      }
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$exitosos módulos creados, $fallidos fallidos.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo leer el CSV.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.canManage
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'modulos-csv',
                  onPressed: _importing ? null : _importCsv,
                  tooltip: 'Importar CSV',
                  child: _importing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.fileUp),
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton(
                  heroTag: 'modulos-new',
                  onPressed: () => _openForm(),
                  child: const Icon(LucideIcons.plus),
                ),
              ],
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingScreenWidget();

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.canManage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Ver ocultos', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                Switch(
                  value: _showInactive,
                  onChanged: (value) {
                    setState(() => _showInactive = value);
                    _load();
                  },
                ),
              ],
            ),
          ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.canManage ? 'Todavía no hay módulos. Creá el primero.' : 'Este curso no tiene módulos todavía.',
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final modulo = _items[index];
          return Opacity(
            opacity: modulo.activo ? 1 : 0.5,
            child: EdumonCard(
              onTap: widget.canManage && modulo.activo ? () => _openForm(existing: modulo) : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(modulo.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (modulo.descripcion != null && modulo.descripcion!.isNotEmpty)
                          Text(modulo.descripcion!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (widget.canManage)
                    modulo.activo
                        ? IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                            onPressed: () => _delete(modulo),
                          )
                        : IconButton(
                            icon: const Icon(LucideIcons.rotateCcw, size: 18, color: AppColors.success),
                            tooltip: 'Restaurar',
                            onPressed: () => _restore(modulo),
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
