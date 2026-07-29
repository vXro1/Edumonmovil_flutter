import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/entrega.dart';
import '../../domain/repositories/entregas_repository.dart';
import '../providers/entregas_providers.dart';

/// Realizar entrega (rol padre) — BLUEPRINT.md FASE 3.4.7.
/// canEdit solo si no hay entrega o está en borrador; canSend solo si borrador.
class RealizarEntregaScreen extends ConsumerStatefulWidget {
  const RealizarEntregaScreen({super.key, required this.tareaId});

  final String tareaId;

  @override
  ConsumerState<RealizarEntregaScreen> createState() => _RealizarEntregaScreenState();
}

class _RealizarEntregaScreenState extends ConsumerState<RealizarEntregaScreen> {
  final _textoController = TextEditingController();
  final List<PlatformFile> _archivosNuevos = [];

  Entrega? _entrega;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _canEdit => _entrega == null || _entrega!.esBorrador;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entrega = await ref.read(entregasRepositoryProvider).fetchMiEntrega(widget.tareaId);
      if (!mounted) return;
      _textoController.text = entrega?.textoRespuesta ?? '';
      setState(() {
        _entrega = entrega;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar la entrega.';
      });
    }
  }

  Future<void> _pickArchivos() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() => _archivosNuevos.addAll(result.files.where((f) => f.bytes != null)));
  }

  Future<void> _guardarBorrador({bool enviar = false}) async {
    final texto = _textoController.text.trim();
    if (enviar && texto.isEmpty && _archivosNuevos.isEmpty && (_entrega?.archivos.isEmpty ?? true)) {
      setState(() => _error = 'Escribí una respuesta o adjuntá al menos un archivo.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(entregasRepositoryProvider);
      final archivos = _archivosNuevos.map((f) => ArchivoUpload(bytes: f.bytes!, filename: f.name)).toList();

      Entrega entrega;
      if (_entrega == null) {
        final padreId = ref.read(authControllerProvider).user!.id;
        entrega = await repo.crearBorrador(
          tareaId: widget.tareaId,
          padreId: padreId,
          textoRespuesta: texto,
          archivos: archivos.isEmpty ? null : archivos,
        );
      } else {
        entrega = await repo.actualizarBorrador(
          id: _entrega!.id,
          textoRespuesta: texto,
          archivosNuevos: archivos.isEmpty ? null : archivos,
        );
      }

      if (enviar) {
        await repo.enviarEntrega(entrega.id);
      }

      if (!mounted) return;
      setState(() {
        _saving = false;
        _archivosNuevos.clear();
      });
      _load();
      if (enviar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrega enviada.')));
      }
    } catch (e) {
      if (!mounted) return;
      // entregaController.js real (pull 85fa452): condición de carrera al
      // crear dos entregas iguales (mismo tareaId+padreId) ahora da 409 en
      // vez de 500 — ya existe una entrega guardada por la otra request, así
      // que en vez de dejar el formulario roto se recarga para mostrarla.
      if (e is AppException && e.statusCode == 409) {
        setState(() => _saving = false);
        _load();
        return;
      }
      setState(() {
        _saving = false;
        _error = e is AppException ? e.message : 'No se pudo guardar la entrega.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi entrega')),
      body: _loading ? const LoadingScreenWidget() : _buildBody(),
    );
  }

  Widget _buildBody() {
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
          if (_entrega?.calificacion != null) ...[
            EdumonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calificación', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 20,
                        color: i < _entrega!.calificacion!.valoracion ? AppColors.warning : AppColors.neutral200,
                      ),
                    ),
                  ),
                  if (_entrega!.calificacion!.comentario != null && _entrega!.calificacion!.comentario!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_entrega!.calificacion!.comentario!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!_canEdit && _entrega != null) ...[
            EdumonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado: ${_entrega!.estado}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_entrega!.textoRespuesta != null && _entrega!.textoRespuesta!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_entrega!.textoRespuesta!),
                  ],
                ],
              ),
            ),
          ] else ...[
            EdumonTextField(controller: _textoController, label: 'Tu respuesta'),
            const SizedBox(height: AppSpacing.sm),
            const Text('Archivos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _entrega?.archivos ?? const [])
                  Chip(avatar: const Icon(LucideIcons.file, size: 14), label: Text(a.nombre, overflow: TextOverflow.ellipsis)),
                for (final f in _archivosNuevos)
                  Chip(
                    label: Text(f.name, overflow: TextOverflow.ellipsis),
                    onDeleted: () => setState(() => _archivosNuevos.remove(f)),
                  ),
                ActionChip(
                  avatar: const Icon(LucideIcons.paperclip, size: 16),
                  label: const Text('Adjuntar (máx. 5)'),
                  onPressed: (_archivosNuevos.length + (_entrega?.archivos.length ?? 0)) >= 5 ? null : _pickArchivos,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: EdumonButton(
                    label: 'Guardar borrador',
                    variant: EdumonButtonVariant.outline,
                    onPressed: _saving ? null : () => _guardarBorrador(),
                    loading: _saving,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EdumonButton(
                    label: 'Enviar entrega',
                    onPressed: _saving ? null : () => _guardarBorrador(enviar: true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
