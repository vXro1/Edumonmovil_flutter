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
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/models/archivo.dart';
import '../../../../shared/widgets/archivos_adjuntos_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../tareas/domain/entities/tarea.dart';
import '../../../tareas/presentation/providers/tareas_providers.dart';
import '../../domain/entities/entrega.dart';
import '../../domain/repositories/entregas_repository.dart';
import '../providers/entregas_providers.dart';
import '../widgets/calificacion_widgets.dart';

/// Mi entrega (rol padre)
/// Muestra el reto, el estado de la entrega y, una vez calificada, las
/// estrellas y la retroalimentación del docente. Solo se edita mientras no
/// exista entrega o esté en borrador (updateEntrega rechaza lo demás).
class RealizarEntregaScreen extends ConsumerStatefulWidget {
  const RealizarEntregaScreen({super.key, required this.tareaId});

  final String tareaId;

  @override
  ConsumerState<RealizarEntregaScreen> createState() => _RealizarEntregaScreenState();
}

class _RealizarEntregaScreenState extends ConsumerState<RealizarEntregaScreen> {
  final _textoController = TextEditingController();
  final List<PlatformFile> _archivosNuevos = [];
  List<EnlaceEntrega> _enlaces = [];
  bool _enlacesModificados = false;

  Tarea? _tarea;
  Entrega? _entrega;
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;
  String? _error;
  bool _loadFailed = false;

  bool get _canEdit => (_entrega == null || _entrega!.esBorrador) && !(_tarea?.cerrada ?? false);

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
      _loadFailed = false;
    });
    try {
      final results = await Future.wait([
        ref.read(tareasRepositoryProvider).fetchTareaById(widget.tareaId),
        ref.read(entregasRepositoryProvider).fetchMiEntrega(widget.tareaId),
      ]);
      if (!mounted) return;
      final entrega = results[1] as Entrega?;
      _textoController.text = entrega?.textoRespuesta ?? '';
      setState(() {
        _tarea = results[0] as Tarea;
        _entrega = entrega;
        _enlaces = [for (final e in entrega?.enlaces ?? const <Archivo>[]) EnlaceEntrega(url: e.url, titulo: e.nombre == e.url ? null : e.nombre)];
        _enlacesModificados = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar la entrega.';
        _loadFailed = true;
      });
    }
  }

  Future<void> _pickArchivos() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    final espacio = 5 - _archivosNuevos.length - (_entrega?.archivos.length ?? 0);
    setState(() => _archivosNuevos.addAll(result.files.where((f) => f.bytes != null).take(espacio < 0 ? 0 : espacio)));
  }

  Future<void> _agregarEnlace() async {
    final urlController = TextEditingController();
    final tituloController = TextEditingController();
    String? error;
    final enlace = await showDialog<EnlaceEntrega>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar enlace'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EdumonTextField(
                controller: urlController,
                label: 'Enlace (https://...)',
                keyboardType: TextInputType.url,
                errorText: error,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              EdumonTextField(controller: tituloController, label: 'Título (opcional)'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                var url = urlController.text.trim();
                if (url.isNotEmpty && !url.contains('://')) url = 'https://$url';
                final uri = Uri.tryParse(url);
                if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
                  setDialogState(() => error = 'Escribe un enlace válido.');
                  return;
                }
                Navigator.of(context).pop(EnlaceEntrega(url: url, titulo: tituloController.text.trim()));
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (enlace == null) return;
    setState(() {
      _enlaces = [..._enlaces, enlace];
      _enlacesModificados = true;
    });
  }

  // eliminarArchivoEntrega: quita un solo adjunto ya subido sin borrar
  // toda la entrega.
  Future<void> _eliminarArchivoExistente(Archivo archivo) async {
    if (_entrega == null) return;
    setState(() => _saving = true);
    try {
      final entrega = await ref.read(entregasRepositoryProvider).eliminarArchivoEntrega(id: _entrega!.id, archivoId: archivo.id);
      if (!mounted) return;
      setState(() {
        _entrega = entrega;
        _saving = false;
        _changed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is AppException ? e.message : 'No se pudo quitar el archivo.';
        _loadFailed = false;
      });
    }
  }

  Future<void> _guardar({bool enviar = false}) async {
    final texto = _textoController.text.trim();
    final sinContenido = texto.isEmpty && _archivosNuevos.isEmpty && (_entrega?.archivos.isEmpty ?? true) && _enlaces.isEmpty;
    if (enviar && sinContenido) {
      setState(() {
        _error = 'Escribe una respuesta, adjunta un archivo o agrega un enlace antes de enviar.';
        _loadFailed = false;
      });
      return;
    }

    if (enviar) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enviar entrega'),
          content: Text(
            (_tarea?.vencida ?? false)
                ? 'El plazo ya venció: la entrega quedará marcada como "tarde". Una vez enviada no podrás modificarla. ¿Enviar?'
                : 'Una vez enviada no podrás modificarla. ¿Enviar tu entrega al docente?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Revisar')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Enviar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _loadFailed = false;
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
          enlaces: _enlaces,
        );
      } else {
        entrega = await repo.actualizarBorrador(
          id: _entrega!.id,
          textoRespuesta: texto,
          archivosNuevos: archivos.isEmpty ? null : archivos,
          enlaces: _enlacesModificados ? _enlaces : null,
        );
      }

      if (enviar) await repo.enviarEntrega(entrega.id);

      if (!mounted) return;
      setState(() {
        _saving = false;
        _changed = true;
        _archivosNuevos.clear();
      });
      ref.invalidate(entregasPendientesCountProvider);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enviar ? '¡Entrega enviada! El docente ya puede revisarla.' : 'Borrador guardado.')),
      );
    } catch (e) {
      if (!mounted) return;
      // Condición de carrera al crear dos entregas iguales → 409: ya existe,
      // se recarga para mostrarla en vez de dejar el formulario roto.
      if (e is AppException && e.statusCode == 409) {
        setState(() => _saving = false);
        _load();
        return;
      }
      setState(() {
        _saving = false;
        _error = e is AppException ? e.message : 'No se pudo guardar la entrega.';
        _loadFailed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi entrega')),
        body: _loading
            ? const LoadingScreenWidget()
            : RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final tarea = _tarea;
    final entrega = _entrega;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_error != null) ...[
          _ErrorBanner(mensaje: _error!, onRetry: _loadFailed ? _load : null),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (tarea != null) ...[_RetoResumen(tarea: tarea, entrega: entrega), const SizedBox(height: AppSpacing.md)],
        if (entrega != null && !entrega.esBorrador) ...[
          if (entrega.calificacion != null)
            CalificacionCard(calificacion: entrega.calificacion!)
          else
            _InfoBanner(
              icon: LucideIcons.hourglass,
              texto: 'Tu entrega fue enviada${entrega.fechaEnvio != null ? ' el ${formatFechaHora(entrega.fechaEnvio!)}' : ''}. '
                  'El docente todavía no la ha calificado; te llegará una notificación cuando lo haga.',
            ),
          const SizedBox(height: AppSpacing.md),
          _MiRespuesta(entrega: entrega),
        ] else if (!_canEdit) ...[
          const _InfoBanner(icon: LucideIcons.lock, texto: 'Este reto está cerrado y ya no acepta entregas.'),
        ] else
          ..._formulario(),
      ],
    );
  }

  List<Widget> _formulario() {
    final existentes = _entrega?.archivos ?? const <Archivo>[];
    final totalArchivos = existentes.length + _archivosNuevos.length;
    return [
      if (_entrega != null)
        const _InfoBanner(
          icon: LucideIcons.filePen,
          texto: 'Tienes un borrador guardado. El docente no lo verá hasta que presiones "Enviar entrega".',
        ),
      if (_entrega != null) const SizedBox(height: AppSpacing.md),
      const Text('Tu respuesta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: AppSpacing.xs),
      EdumonTextField(
        controller: _textoController,
        hint: 'Escribe aquí tu respuesta al reto...',
        minLines: 4,
        maxLines: 10,
        keyboardType: TextInputType.multiline,
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          const Expanded(child: Text('Archivos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          Text('$totalArchivos/5', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      if (existentes.isNotEmpty)
        ArchivosAdjuntosView(archivos: existentes, onDelete: _saving ? null : _eliminarArchivoExistente),
      for (final f in _archivosNuevos)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.fileUp),
          title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: const Text('Se subirá al guardar'),
          trailing: IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: 'Quitar ${f.name}',
            onPressed: () => setState(() => _archivosNuevos.remove(f)),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: totalArchivos >= 5 || _saving ? null : _pickArchivos,
          icon: const Icon(LucideIcons.paperclip, size: 18),
          label: const Text('Adjuntar archivo'),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text('Enlaces', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      for (final e in _enlaces)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.link),
          title: Text(e.titulo?.isNotEmpty == true ? e.titulo! : e.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: e.titulo?.isNotEmpty == true ? Text(e.url, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: 'Quitar enlace',
            onPressed: () => setState(() {
              _enlaces = [..._enlaces]..remove(e);
              _enlacesModificados = true;
            }),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _enlaces.length >= 10 || _saving ? null : _agregarEnlace,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Agregar enlace (Drive, YouTube...)'),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      EdumonButton(
        label: 'Enviar entrega',
        leftIcon: LucideIcons.send,
        fullWidth: true,
        size: EdumonButtonSize.lg,
        loading: _saving,
        onPressed: _saving ? null : () => _guardar(enviar: true),
      ),
      const SizedBox(height: AppSpacing.sm),
      EdumonButton(
        label: 'Guardar borrador',
        variant: EdumonButtonVariant.outline,
        fullWidth: true,
        onPressed: _saving ? null : () => _guardar(),
      ),
    ];
  }
}

class _RetoResumen extends StatelessWidget {
  const _RetoResumen({required this.tarea, required this.entrega});

  final Tarea tarea;
  final Entrega? entrega;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedText(context);
    return EdumonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstadoEntregaBadge(entrega: entrega, tarea: tarea),
          const SizedBox(height: AppSpacing.sm),
          Text(tarea.titulo, style: Theme.of(context).textTheme.titleLarge),
          if (tarea.cursoNombre != null || tarea.docenteNombre != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [?tarea.cursoNombre, if (tarea.docenteNombre != null) 'Docente: ${tarea.docenteNombre}'].join(' · '),
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
          if (tarea.fechaEntrega != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(LucideIcons.calendarClock, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fecha límite: ${formatFechaHora(tarea.fechaEntrega!)}'
                    '${entrega == null || entrega!.esBorrador ? ' · ${tiempoRestante(tarea.fechaEntrega!)}' : ''}',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          if (entrega?.fechaEnvio != null && !entrega!.esBorrador)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(LucideIcons.send, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Text('Enviada: ${formatFechaHora(entrega!.fechaEnvio!)}', style: TextStyle(color: muted, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiRespuesta extends StatelessWidget {
  const _MiRespuesta({required this.entrega});

  final Entrega entrega;

  @override
  Widget build(BuildContext context) {
    final adjuntos = [...entrega.archivos, ...entrega.enlaces];
    return EdumonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Lo que entregaste', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          if (entrega.textoRespuesta?.trim().isNotEmpty ?? false)
            SelectableText(entrega.textoRespuesta!.trim(), style: const TextStyle(fontSize: 15, height: 1.4))
          else if (adjuntos.isEmpty)
            Text('Sin contenido.', style: TextStyle(color: AppColors.mutedText(context))),
          if (adjuntos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ArchivosAdjuntosView(archivos: adjuntos),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = isDark ? AppColors.blue300 : AppColors.blue700;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14, height: 1.35))),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.mensaje, this.onRetry});

  final String mensaje;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.errorSurface(context.isDarkMode),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje, style: TextStyle(color: context.isDarkMode ? AppColors.error : AppColors.errorHover, fontSize: 14)),
            if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
