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
import '../../../../shared/models/archivo.dart';
import '../../../cursos/domain/entities/modulo.dart';
import '../../../cursos/presentation/providers/cursos_providers.dart';
import '../../domain/entities/tarea.dart';
import '../../domain/repositories/tareas_repository.dart';
import '../providers/tareas_providers.dart';

/// Crear/editar reto (Tarea) — BLUEPRINT.md FASE 3.4.4, verificado contra
/// tareaController.js/tareaValidator.js/Tarea.js reales.
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
  final _etiquetasController = TextEditingController();
  final _criteriosController = TextEditingController();

  DateTime? _fechaEntrega;
  TipoEntrega _tipoEntrega = TipoEntrega.archivo;
  AsignacionTipo _asignacionTipo = AsignacionTipo.todos;
  final Set<String> _seleccionados = {};
  final List<PlatformFile> _archivosNuevos = [];
  final List<EnlaceInput> _enlacesNuevos = [];

  // Solo se llenan al editar — adjuntos que la tarea ya tenía en el backend.
  List<Archivo> _archivosExistentes = const [];
  final Set<String> _archivosAEliminar = {};

  List<Modulo> _modulos = const [];
  String? _moduloId;
  bool _loadingModulos = true;

  bool _loadingTarea = false;
  bool _saving = false;

  bool get _isEditing => widget.tareaId != null;

  @override
  void initState() {
    super.initState();
    _loadModulos();
    if (_isEditing) _loadTarea();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _etiquetasController.dispose();
    _criteriosController.dispose();
    super.dispose();
  }

  // moduloId es obligatorio en el backend (Tarea.js: `required`) — sin un
  // módulo elegido, POST /tareas devuelve 400 "El ID del módulo es
  // obligatorio". Se carga la lista de módulos del curso para elegir uno.
  Future<void> _loadModulos() async {
    try {
      final modulos = await ref.read(modulosRepositoryProvider).fetchModulos(widget.cursoId);
      if (!mounted) return;
      setState(() {
        _modulos = modulos;
        _loadingModulos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingModulos = false);
    }
  }

  Future<void> _loadTarea() async {
    setState(() => _loadingTarea = true);
    try {
      final tarea = await ref.read(tareasRepositoryProvider).fetchTareaById(widget.tareaId!);
      if (!mounted) return;
      _tituloController.text = tarea.titulo;
      _descripcionController.text = tarea.descripcion ?? '';
      _etiquetasController.text = tarea.etiquetas.join(', ');
      _criteriosController.text = tarea.criterios ?? '';
      setState(() {
        _fechaEntrega = tarea.fechaEntrega;
        _tipoEntrega = tarea.tipoEntrega;
        _asignacionTipo = tarea.asignacionTipo;
        _seleccionados.addAll(tarea.participantesSeleccionados);
        _moduloId = tarea.moduloId;
        _archivosExistentes = tarea.archivos;
        _loadingTarea = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTarea = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo cargar el reto.');
    }
  }

  Future<void> _pickFechaEntrega() async {
    // createTareaValidator real: fechaEntrega es obligatoria y debe ser
    // futura (`new Date(value) < new Date()` rechaza con 400) — permitir
    // elegir hasta un año atrás garantizaba ese 400 al crear.
    // updateTareaValidator no tiene esa restricción, así que al editar se
    // mantiene el rango amplio.
    final primerDiaPermitido = _isEditing
        ? DateTime.now().subtract(const Duration(days: 365))
        : DateTime.now();
    final inicial = _fechaEntrega ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(primerDiaPermitido) ? primerDiaPermitido : inicial,
      firstDate: primerDiaPermitido,
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

  Future<void> _agregarEnlace() async {
    final urlController = TextEditingController();
    final nombreController = TextEditingController();

    final enlace = await showDialog<EnlaceInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar enlace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EdumonTextField(controller: nombreController, label: 'Nombre'),
            const SizedBox(height: AppSpacing.sm),
            EdumonTextField(controller: urlController, label: 'URL', keyboardType: TextInputType.url),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) return;
              Navigator.of(context).pop(
                EnlaceInput(url: url, nombre: nombreController.text.trim().isEmpty ? url : nombreController.text.trim()),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (enlace == null) return;
    setState(() => _enlacesNuevos.add(enlace));
  }

  Future<void> _submit() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      EdumonDialog.show(context, message: 'Ingresá un título.');
      return;
    }
    if (_moduloId == null) {
      EdumonDialog.show(context, message: 'Seleccioná un módulo.');
      return;
    }
    if (_asignacionTipo == AsignacionTipo.seleccionados && _seleccionados.isEmpty) {
      EdumonDialog.show(context, message: 'Seleccioná al menos un participante.');
      return;
    }
    // createTareaValidator real: fechaEntrega es obligatoria (`notEmpty()`)
    // — sin este chequeo, crear un reto sin elegir fecha se mandaba con
    // "fechaEntrega" ausente del FormData y el backend siempre respondía 400.
    if (!_isEditing && _fechaEntrega == null) {
      EdumonDialog.show(context, message: 'Seleccioná la fecha de entrega.');
      return;
    }

    setState(() => _saving = true);
    try {
      // tareaController.js real ignora docenteId en el body y siempre usa el
      // token de quien crea la tarea — ya no hace falta resolverlo acá.
      final archivos = _archivosNuevos
          .map((f) => ArchivoUpload(bytes: f.bytes!, filename: f.name))
          .toList();
      final etiquetas = _etiquetasController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final criterios = _criteriosController.text.trim();

      final repo = ref.read(tareasRepositoryProvider);
      if (_isEditing) {
        await repo.updateTarea(
          id: widget.tareaId!,
          titulo: titulo,
          descripcion: _descripcionController.text.trim(),
          moduloId: _moduloId,
          fechaEntrega: _fechaEntrega,
          asignacionTipo: _asignacionTipo,
          tipoEntrega: _tipoEntrega,
          participantesSeleccionados: _asignacionTipo == AsignacionTipo.seleccionados ? _seleccionados.toList() : null,
          etiquetas: etiquetas,
          criterios: criterios,
          archivosNuevos: archivos.isEmpty ? null : archivos,
          enlacesNuevos: _enlacesNuevos.isEmpty ? null : _enlacesNuevos,
          archivosAEliminar: _archivosAEliminar.isEmpty ? null : _archivosAEliminar.toList(),
        );
      } else {
        await repo.createTarea(
          titulo: titulo,
          descripcion: _descripcionController.text.trim(),
          cursoId: widget.cursoId,
          moduloId: _moduloId!,
          fechaEntrega: _fechaEntrega,
          asignacionTipo: _asignacionTipo,
          tipoEntrega: _tipoEntrega,
          participantesSeleccionados: _asignacionTipo == AsignacionTipo.seleccionados ? _seleccionados.toList() : null,
          etiquetas: etiquetas,
          criterios: criterios,
          archivos: archivos.isEmpty ? null : archivos,
          enlaces: _enlacesNuevos.isEmpty ? null : _enlacesNuevos,
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
                  const Text('Módulo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  _loadingModulos
                      ? const LinearProgressIndicator()
                      : _modulos.isEmpty
                          ? Text(
                              'Este curso todavía no tiene módulos — creá uno primero en la pestaña Módulos.',
                              style: TextStyle(color: AppColors.error, fontSize: 12),
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _modulos.any((m) => m.id == _moduloId) ? _moduloId : null,
                              isExpanded: true,
                              items: _modulos
                                  .map((m) => DropdownMenuItem(value: m.id, child: Text(m.titulo, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (value) => setState(() => _moduloId = value),
                              hint: const Text('Seleccioná un módulo'),
                            ),
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
                  const Text('Etiquetas (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  EdumonTextField(controller: _etiquetasController, label: 'Separadas por coma'),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Criterios de evaluación (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  EdumonTextField(controller: _criteriosController, label: 'Criterios', maxLines: 4),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Archivos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in _archivosExistentes.where((a) => !_archivosAEliminar.contains(a.publicId)))
                        Chip(
                          avatar: Icon(a.esEnlace ? LucideIcons.link : LucideIcons.file, size: 16),
                          label: Text(a.nombre, overflow: TextOverflow.ellipsis),
                          onDeleted: a.publicId == null
                              ? null
                              : () => setState(() => _archivosAEliminar.add(a.publicId!)),
                        ),
                      for (final f in _archivosNuevos)
                        Chip(
                          label: Text(f.name, overflow: TextOverflow.ellipsis),
                          onDeleted: () => setState(() => _archivosNuevos.remove(f)),
                        ),
                      for (final e in _enlacesNuevos)
                        Chip(
                          avatar: const Icon(LucideIcons.link, size: 16),
                          label: Text(e.nombre, overflow: TextOverflow.ellipsis),
                          onDeleted: () => setState(() => _enlacesNuevos.remove(e)),
                        ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.paperclip, size: 16),
                        label: const Text('Adjuntar'),
                        onPressed: _pickArchivos,
                      ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.link, size: 16),
                        label: const Text('Enlace'),
                        onPressed: _agregarEnlace,
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
