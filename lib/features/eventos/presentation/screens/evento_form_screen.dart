import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cursos/domain/entities/curso.dart';
import '../../../cursos/presentation/providers/cursos_providers.dart';
import '../../domain/entities/evento.dart';
import '../../domain/repositories/eventos_repository.dart';
import '../providers/eventos_providers.dart';

/// Crear/editar evento — BLUEPRINT.md FASE 3.6.
/// [eventoId] null = crear; con valor = editar.
class EventoFormScreen extends ConsumerStatefulWidget {
  const EventoFormScreen({super.key, this.eventoId, this.initialCursoId});

  final String? eventoId;

  /// Preselecciona un curso en el multi-select (ej. al crear desde el tab
  /// Calendario de un curso puntual) — no aplica si [eventoId] ya trae los
  /// suyos propios desde el backend.
  final String? initialCursoId;

  @override
  ConsumerState<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends ConsumerState<EventoFormScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  EventoCategoria _categoria = EventoCategoria.institucional;
  final Set<String> _cursosSeleccionados = {};

  PlatformFile? _adjuntoNuevo;
  String? _adjuntoNombreExistente;

  List<Curso> _cursosDisponibles = const [];
  bool _loadingCursos = true;
  bool _loadingEvento = false;
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isEditing => widget.eventoId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialCursoId != null) _cursosSeleccionados.add(widget.initialCursoId!);
    _loadCursos();
    if (_isEditing) _loadEvento();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _loadCursos() async {
    try {
      final rol = ref.read(authControllerProvider).user?.rol;
      final repo = ref.read(cursosRepositoryProvider);
      final result = rol == UserRole.docente
          ? await repo.fetchMisCursos(page: 1, limit: 100)
          : await repo.fetchCursos(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _cursosDisponibles = result.items;
        _loadingCursos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCursos = false);
    }
  }

  Future<void> _loadEvento() async {
    setState(() => _loadingEvento = true);
    try {
      final evento = await ref.read(eventosRepositoryProvider).fetchEventoById(widget.eventoId!);
      if (!mounted) return;
      _tituloController.text = evento.titulo;
      _descripcionController.text = evento.descripcion ?? '';
      _ubicacionController.text = evento.ubicacion ?? '';
      setState(() {
        _fechaInicio = evento.fechaInicio;
        _fechaFin = evento.fechaFin;
        _categoria = evento.categoria;
        _cursosSeleccionados.addAll(evento.cursosIds);
        _adjuntoNombreExistente = evento.adjunto?.nombre;
        _loadingEvento = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingEvento = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo cargar el evento.');
    }
  }

  Future<void> _pickFecha({required bool esInicio}) async {
    final inicial = (esInicio ? _fechaInicio : _fechaFin) ?? _fechaInicio ?? DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(inicial));
    if (!mounted) return;
    final combinada = DateTime(fecha.year, fecha.month, fecha.day, hora?.hour ?? 0, hora?.minute ?? 0);
    setState(() {
      if (esInicio) {
        _fechaInicio = combinada;
      } else {
        _fechaFin = combinada;
      }
    });
  }

  Future<void> _pickAdjunto() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    setState(() => _adjuntoNuevo = file);
  }

  Future<void> _submit() async {
    final titulo = _tituloController.text.trim();
    final errors = <String, String>{};
    if (titulo.isEmpty) errors['titulo'] = 'Ingresá un título.';
    if (_fechaInicio == null) errors['fechaInicio'] = 'Seleccioná la fecha de inicio.';

    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;

    final hora = _fechaInicio != null
        ? '${_fechaInicio!.hour.toString().padLeft(2, '0')}:${_fechaInicio!.minute.toString().padLeft(2, '0')}'
        : null;

    setState(() => _saving = true);
    try {
      final repo = ref.read(eventosRepositoryProvider);
      final adjunto = _adjuntoNuevo?.bytes != null
          ? ArchivoUpload(bytes: _adjuntoNuevo!.bytes!, filename: _adjuntoNuevo!.name)
          : null;

      if (_isEditing) {
        await repo.updateEvento(
          id: widget.eventoId!,
          titulo: titulo,
          descripcion: _descripcionController.text.trim(),
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          hora: hora,
          ubicacion: _ubicacionController.text.trim(),
          categoria: _categoria,
          cursosIds: _cursosSeleccionados.toList(),
          adjunto: adjunto,
        );
      } else {
        await repo.createEvento(
          titulo: titulo,
          descripcion: _descripcionController.text.trim(),
          fechaInicio: _fechaInicio!,
          fechaFin: _fechaFin,
          hora: hora,
          ubicacion: _ubicacionController.text.trim(),
          categoria: _categoria,
          cursosIds: _cursosSeleccionados.toList(),
          adjunto: adjunto,
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
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo guardar el evento.');
    }
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar evento' : 'Nuevo evento')),
      body: _loadingEvento
          ? const LoadingScreenWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EdumonTextField(controller: _tituloController, label: 'Título', errorText: _fieldErrors['titulo']),
                  EdumonTextField(controller: _descripcionController, label: 'Descripción (opcional)', maxLines: 4, minLines: 3),
                  EdumonTextField(controller: _ubicacionController, label: 'Ubicación (opcional)'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Fecha inicio',
                          value: _formatFecha(_fechaInicio),
                          error: _fieldErrors['fechaInicio'],
                          onTap: () => _pickFecha(esInicio: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _DateField(
                          label: 'Fecha fin (opcional)',
                          value: _formatFecha(_fechaFin),
                          onTap: () => _pickFecha(esInicio: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Categoría', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<EventoCategoria>(
                    initialValue: _categoria,
                    isExpanded: true,
                    items: EventoCategoria.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _categoria = value ?? _categoria),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAdjunto,
                          icon: const Icon(LucideIcons.paperclip, size: 16),
                          label: Text(
                            _adjuntoNuevo?.name ?? _adjuntoNombreExistente ?? 'Adjuntar archivo',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Cursos asociados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (_loadingCursos)
                    const LinearProgressIndicator()
                  else if (_cursosDisponibles.isEmpty)
                    Text('No tenés cursos disponibles.', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12))
                  else
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: _cursosDisponibles.map((c) {
                        final selected = _cursosSeleccionados.contains(c.id);
                        return FilterChip(
                          label: Text(c.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: selected,
                          onSelected: (value) => setState(() {
                            if (value) {
                              _cursosSeleccionados.add(c.id);
                            } else {
                              _cursosSeleccionados.remove(c.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  EdumonButton(
                    label: _isEditing ? 'Guardar cambios' : 'Crear evento',
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

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.error});

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: error),
        child: Text(value),
      ),
    );
  }
}
