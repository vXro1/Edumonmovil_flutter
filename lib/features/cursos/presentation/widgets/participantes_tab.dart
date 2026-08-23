import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/participante.dart';
import '../providers/cursos_providers.dart';

/// Tab Participantes — BLUEPRINT.md FASE 3.4.9.
/// A diferencia de Módulos, acá SÍ hay endpoint masivo real
/// (POST /cursos/:id/usuarios-masivo, parseo server-side).
class ParticipantesTab extends ConsumerStatefulWidget {
  const ParticipantesTab({super.key, required this.cursoId, required this.canManage});

  final String cursoId;
  final bool canManage;

  @override
  ConsumerState<ParticipantesTab> createState() => _ParticipantesTabState();
}

class _ParticipantesTabState extends ConsumerState<ParticipantesTab> {
  List<Participante> _items = const [];
  bool _loading = true;
  bool _importing = false;
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
      final items = await ref.read(cursosRepositoryProvider).fetchParticipantes(widget.cursoId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los participantes.';
      });
    }
  }

  Future<void> _openAddForm() async {
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final cedulaController = TextEditingController();
    final telefonoController = TextEditingController();
    String? error;

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
                const Text('Agregar participante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                ],
                EdumonTextField(controller: nombreController, label: 'Nombre'),
                EdumonTextField(controller: apellidoController, label: 'Apellido'),
                EdumonTextField(
                  controller: cedulaController,
                  label: 'Cédula',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                ),
                EdumonTextField(
                  controller: telefonoController,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                ),
                const SizedBox(height: 4),
                Text('La contraseña inicial será su cédula.', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                const SizedBox(height: AppSpacing.sm),
                EdumonButton(
                  label: 'Agregar',
                  fullWidth: true,
                  onPressed: () async {
                    final nombre = nombreController.text.trim();
                    final apellido = apellidoController.text.trim();
                    final cedula = cedulaController.text.trim();
                    final telefono = telefonoController.text.trim();

                    if (nombre.isEmpty || apellido.isEmpty) {
                      setSheetState(() => error = 'Completá nombre y apellido.');
                      return;
                    }
                    if (!AppConstants.cedulaRegex.hasMatch(cedula)) {
                      setSheetState(() => error = 'La cédula debe tener entre 6 y 10 dígitos.');
                      return;
                    }
                    if (!AppConstants.phoneRegex.hasMatch(telefono)) {
                      setSheetState(() => error = 'El teléfono debe tener 10 dígitos.');
                      return;
                    }
                    try {
                      await ref
                          .read(cursosRepositoryProvider)
                          .addParticipante(cursoId: widget.cursoId, nombre: nombre, apellido: apellido, cedula: cedula, telefono: telefono);
                      if (context.mounted) Navigator.of(context).pop(true);
                    } catch (e) {
                      setSheetState(() => error = e is AppException ? e.message : 'No se pudo agregar el participante.');
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

  Future<void> _remove(Participante participante) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar participante'),
        content: Text('¿Quitar a ${participante.user.nombreCompleto} del curso?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(cursosRepositoryProvider).removeParticipante(cursoId: widget.cursoId, usuarioId: participante.user.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo quitar.')));
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _importing = true);
    try {
      final summary = await ref
          .read(cursosRepositoryProvider)
          .importParticipantesCsv(cursoId: widget.cursoId, bytes: file.bytes!, filename: file.name);
      if (!mounted) return;
      setState(() => _importing = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resultado de la importación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total procesados: ${summary.total}', style: TextStyle(color: AppColors.mutedText(context))),
                const SizedBox(height: 4),
                _ImportResultRow(
                  icon: LucideIcons.check,
                  color: AppColors.success,
                  text: '${summary.exitosos} agregados',
                ),
                _ImportResultRow(
                  icon: LucideIcons.triangleAlert,
                  color: AppColors.warning,
                  text: '${summary.duplicados} duplicados',
                ),
                _ImportResultRow(
                  icon: LucideIcons.x,
                  color: AppColors.error,
                  text: '${summary.errores} con error',
                ),
                if (summary.detallesErrores.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Errores:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ...summary.detallesErrores.take(10).map(
                    (e) => Text('• ${e.nombre.isNotEmpty ? e.nombre : e.cedula}: ${e.motivo}', style: const TextStyle(fontSize: 12)),
                  ),
                ],
                if (summary.detallesDuplicados.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Duplicados:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ...summary.detallesDuplicados.take(10).map(
                    (e) => Text('• ${e.nombre.isNotEmpty ? e.nombre : e.cedula}: ${e.motivo}', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo importar el CSV.')));
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
                  heroTag: 'participantes-csv',
                  onPressed: _importing ? null : _importCsv,
                  tooltip: 'Importar CSV',
                  child: _importing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.fileUp),
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton(
                  heroTag: 'participantes-new',
                  onPressed: _openAddForm,
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

    if (_items.isEmpty) {
      return Center(child: Text('Todavía no hay participantes.', style: TextStyle(color: AppColors.mutedText(context))));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final participante = _items[index];
          final esDocente = participante.etiqueta == 'docente';
          return EdumonCard(
            child: Row(
              children: [
                EdumonAvatar(
                  radius: 18,
                  imageUrl: participante.user.avatarUrl,
                  fallbackText: participante.user.nombre.isNotEmpty ? participante.user.nombre[0].toUpperCase() : '?',
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(participante.user.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (participante.etiqueta != null)
                        Text(participante.etiqueta!, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                    ],
                  ),
                ),
                if (esDocente)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: const Text('Docente', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                  )
                else if (widget.canManage)
                  IconButton(
                    icon: const Icon(LucideIcons.userMinus, size: 18, color: AppColors.error),
                    tooltip: 'Quitar participante',
                    onPressed: () => _remove(participante),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fila ícono+texto para resultados de importación — sin emojis (regla de diseño).
class _ImportResultRow extends StatelessWidget {
  const _ImportResultRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          // Expanded: `text` es un mensaje de error dinámico (`e.motivo`) que
          // puede ser largo — sin esto, Row(RenderFlex) desbordaba en pantallas
          // angostas en vez de ajustar el texto a varias líneas.
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
