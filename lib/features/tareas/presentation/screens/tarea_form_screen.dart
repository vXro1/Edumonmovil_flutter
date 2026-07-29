import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cursos/presentation/providers/cursos_providers.dart';
import '../../domain/entities/tarea.dart';
import '../../domain/repositories/tareas_repository.dart';
import '../providers/tareas_providers.dart';

/// Crear/editar reto (Tarea) — BLUEPRINT.md FASE 3.4.4.
/// [tareaId] null = crear; con valor = editar.
class TareaFormScreen extends ConsumerStatefulWidget {
  const TareaFormScreen({super.key, required this.cursoId, this.tareaId});

  final String cursoId;
  final String? tareaId;

  @override
  ConsumerState<TareaFormScreen> createState() => _TareaFormScreenState();
}

class _TareaFormScreenState extends ConsumerState<TareaFormScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  DateTime? _fechaEntrega;
  TipoEntrega _tipoEntrega = TipoEntrega.archivo;
  AsignacionTipo _asignacionTipo = AsignacionTipo.todos;
  final Set<String> _seleccionados = {};
  final List<PlatformFile> _archivosNuevos = [];

  bool _loadingTarea = false;
  bool _saving = false;

  bool get _isEditing => widget.tareaId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadTarea();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadTarea() async {
    setState(() => _loadingTarea = true);
    try {
      final tarea = await ref.read(tareasRepositoryProvider).fetchTareaById(widget.tareaId!);
      if (!mounted) return;
      _tituloController.text = tarea.titulo;
      _descripcionController.text = tarea.descripcion ?? '';
      setState(() {
        _fechaEntrega = tarea.fechaEntrega;
        _tipoEntrega = tarea.tipoEntrega;
        _asignacionTipo = tarea.asignacionTipo;
        _seleccionados.addAll(tarea.participantesSeleccionados);
        _loadingTarea = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTarea = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo cargar el reto.');
    }
  }

  Future<void> _pickFechaEntrega() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    setState(() {
      _fechaEntrega = DateTime(date.year, date.month, date.day, time?.hour ?? 23, time?.minute ?? 59);
    });
  }

  Future<void> _pickArchivos() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() => _archivosNuevos.addAll(result.files.where((f) => f.bytes != null)));
  }

  Future<void> _submit() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      EdumonDialog.show(context, message: 'Ingresá un título.');
      return;
    }
    if (_asignacionTipo == AsignacionTipo.seleccionados && _seleccionados.isEmpty) {
      EdumonDialog.show(context, message: 'Seleccioná al menos un participante.');
      return;
    }

    setState(() => _saving = true);
    try {
      // tareaController.js real ignora docenteId en el body y siempre usa el
      // token de quien crea la tarea — ya no hace falta resolverlo acá.
      final archivos = _archivosNuevos
          .map((f) => ArchivoUpload(bytes: f.bytes!, filename: f.name))
          .toList();

      final repo = ref.read(tareasRepositoryProvider);
      if (_isEditing) {
        await repo.updateTarea(
          id: widget.tareaId!,
          titulo: titulo,
          descripcion: _descripcionController.text.trim(),
          fechaEntrega: _fechaEntrega,
          asignacionTipo: _asignacionTipo,
          tipoEntrega: _tipoEntrega,
          participantesSeleccionados: _asignacionTipo == AsignacionTipo.seleccionados ? _seleccionados.toList() : null,
          archivosNuevos: archivos.isEmpty ? null : archivos,
        );
      } else {
        await repo.createTarea(
          titulo: titulo,
          descripcion: _descripcionController.text.trim(),
          cursoId: widget.cursoId,
          fechaEntrega: _fechaEntrega,
          asignacionTipo: _asignacionTipo,
          tipoEntrega: _tipoEntrega,
          participantesSeleccionados: _asignacionTipo == AsignacionTipo.seleccionados ? _seleccionados.toList() : null,
          archivos: archivos.isEmpty ? null : archivos,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo guardar el reto.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar reto' : 'Nuevo reto')),
      body: _loadingTarea
          ? const LoadingScreenWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EdumonTextField(controller: _tituloController, label: 'Título'),
                  EdumonTextField(controller: _descripcionController, label: 'Descripción (opcional)'),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Fecha de entrega', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _pickFechaEntrega,
                    icon: const Icon(LucideIcons.calendar, size: 16),
                    label: Text(
                      _fechaEntrega == null
                          ? 'Sin fecha límite'
                          : '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year} ${_fechaEntrega!.hour.toString().padLeft(2, '0')}:${_fechaEntrega!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Tipo de entrega', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: TipoEntrega.values.map((tipo) {
                      return ChoiceChip(
                        label: Text(tipo.label),
                        selected: _tipoEntrega == tipo,
                        onSelected: (_) => setState(() => _tipoEntrega = tipo),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Asignación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  SegmentedButton<AsignacionTipo>(
                    segments: const [
                      ButtonSegment(value: AsignacionTipo.todos, label: Text('Todos')),
                      ButtonSegment(value: AsignacionTipo.seleccionados, label: Text('Seleccionados')),
                    ],
                    selected: {_asignacionTipo},
                    onSelectionChanged: (s) => setState(() => _asignacionTipo = s.first),
                  ),
                  if (_asignacionTipo == AsignacionTipo.seleccionados) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Consumer(
                      builder: (context, ref, _) {
                        return FutureBuilder(
                          future: ref.read(cursosRepositoryProvider).fetchParticipantes(widget.cursoId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator();
                            final participantes = snapshot.data!.where((p) => p.etiqueta != 'docente').toList();
                            if (participantes.isEmpty) {
                              return Text('No hay participantes en este curso todavía.', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12));
                            }
                            return Column(
                              children: participantes.map((p) {
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(p.user.nombreCompleto),
                                  value: _seleccionados.contains(p.user.id),
                                  onChanged: (checked) => setState(() {
                                    if (checked == true) {
                                      _seleccionados.add(p.user.id);
                                    } else {
                                      _seleccionados.remove(p.user.id);
                                    }
                                  }),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Archivos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in _archivosNuevos)
                        Chip(
                          label: Text(f.name, overflow: TextOverflow.ellipsis),
                          onDeleted: () => setState(() => _archivosNuevos.remove(f)),
                        ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.paperclip, size: 16),
                        label: const Text('Adjuntar'),
                        onPressed: _pickArchivos,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EdumonButton(
                    label: _isEditing ? 'Guardar cambios' : 'Crear reto',
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
