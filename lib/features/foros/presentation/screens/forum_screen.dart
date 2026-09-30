import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cursos/presentation/providers/cursos_providers.dart';
import '../../domain/entities/foro.dart';
import '../../domain/repositories/foros_repository.dart';
import '../providers/foros_providers.dart';
import '../widgets/create_foro_sheet.dart';

/// Vista canónica de Foro — BLUEPRINT.md FASE 3.8.3. Todos los roles usan
/// esta misma página. Layout 3 columnas (Discord-like): sidebar (foros del
/// curso), centro (mensajes+compositor), panel de actividad — colapsa en
/// móvil/tablet según Breakpoint. Polling cada 60s.
/// Permisos por mensaje verificados contra mensajeForoController.js real.
class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key, required this.cursoId, required this.foroId});

  final String cursoId;
  final String foroId;

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  List<Foro> _foros = const [];
  Foro? _foro;
  List<MensajeForo> _mensajes = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  MensajeForo? _replyingTo;
  final _compositorController = TextEditingController();
  final List<PlatformFile> _archivosNuevos = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadMensajes(silent: true));
  }

  @override
  void didUpdateWidget(covariant ForumScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foroId != widget.foroId) {
      _replyingTo = null;
      _compositorController.clear();
      _archivosNuevos.clear();
      _loadAll();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _compositorController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  List<MensajeForo> _allReplies(MensajeForo m) {
    final result = <MensajeForo>[];
    for (final r in m.respuestas) {
      result.add(r);
      result.addAll(_allReplies(r));
    }
    return result;
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(forosRepositoryProvider);
      final foros = await repo.fetchForosPorCurso(widget.cursoId);
      final foro = await repo.fetchForoById(widget.foroId);
      final mensajes = await repo.fetchMensajes(widget.foroId);
      if (!mounted) return;
      setState(() {
        _foros = foros;
        _foro = foro;
        _mensajes = mensajes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar el foro.';
      });
    }
  }

  Future<void> _loadMensajes({bool silent = false}) async {
    try {
      final mensajes = await ref.read(forosRepositoryProvider).fetchMensajes(widget.foroId);
      if (!mounted) return;
      setState(() => _mensajes = mensajes);
    } catch (_) {
      // Polling/refresh silencioso — no interrumpe la conversación con errores.
    }
  }

  Future<void> _toggleEstadoForo() async {
    if (_foro == null) return;
    try {
      await ref.read(forosRepositoryProvider).toggleEstadoForo(id: _foro!.id, cerrado: !_foro!.cerrado);
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo actualizar el foro.')));
    }
  }

  Future<void> _pickArchivos() async {
    // mensajeForoRoutes.js real: solo imágenes, videos y PDF — el resto lo
    // rechaza multer o se descarta en silencio.
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'mpeg', 'pdf'],
    );
    if (result == null) return;
    setState(() {
      final espacio = 5 - _archivosNuevos.length;
      _archivosNuevos.addAll(result.files.where((f) => f.bytes != null).take(espacio < 0 ? 0 : espacio));
    });
  }

  Future<void> _enviarMensaje() async {
    final contenido = _compositorController.text.trim();
    if (contenido.isEmpty && _archivosNuevos.isEmpty) return;

    setState(() => _sending = true);
    try {
      final archivos = _archivosNuevos.map((f) => ArchivoUpload(bytes: f.bytes!, filename: f.name)).toList();
      await ref.read(forosRepositoryProvider).enviarMensaje(
            foroId: widget.foroId,
            contenido: contenido,
            respuestaA: _replyingTo?.id,
            archivos: archivos.isEmpty ? null : archivos,
          );
      _compositorController.clear();
      _archivosNuevos.clear();
      if (!mounted) return;
      setState(() {
        _replyingTo = null;
        _sending = false;
      });
      _loadMensajes();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo enviar el mensaje.')));
    }
  }

  Future<void> _toggleLike(MensajeForo m) async {
    try {
      await ref.read(forosRepositoryProvider).toggleLike(m.id);
      _loadMensajes(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo dar like.')));
    }
  }

  Future<void> _deleteMensaje(MensajeForo m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        // eliminarMensaje real borra también todas las respuestas del mensaje.
        content: Text(
          m.respuestas.isNotEmpty
              ? '¿Eliminar este mensaje y sus ${m.respuestas.length} respuesta(s)? Esta acción no se puede deshacer.'
              : '¿Eliminar este mensaje? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(forosRepositoryProvider).deleteMensaje(m.id);
      _loadMensajes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo eliminar.')));
    }
  }

  Future<void> _editarMensaje(String id, String contenido) async {
    if (contenido.isEmpty) return;
    try {
      await ref.read(forosRepositoryProvider).editarMensaje(id: id, contenido: contenido);
      _loadMensajes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo editar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(authControllerProvider).user?.rol;
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    // Crear foro nuevo: contenido pedagógico, solo Docente (y superAdmin) —
    // Administrador solo visualiza. No depende del foro que se esté viendo
    // ahora — cualquier docente puede crear foros en cursos que enseña.
    final canCreateForo = rol == UserRole.docente || rol == UserRole.superAdmin;
    // Cerrar/reabrir ESTE foro puntual: cambiarEstadoForo real exige además
    // ser el docente CREADOR de ese foro (no cualquier docente) — sin este
    // chequeo, un docente que enseña el curso pero no creó este foro en
    // particular (ej. lo creó un administrador en su curso) veía el botón y
    // el backend le devolvía 403 al usarlo.
    final canManageThisForo =
        (rol == UserRole.docente && _foro?.docenteId == currentUserId) || rol == UserRole.superAdmin;
    // Docente titular del curso: eliminarMensaje real solo deja moderar a un
    // docente en cursos donde él es curso.docenteId.
    final cursoDocenteId = ref.watch(cursoDetailProvider(widget.cursoId)).value?.docenteId ?? _foro?.docenteId;
    final breakpoint = Breakpoint.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_foro?.titulo ?? 'Foro'),
        actions: [
          // getDashboardForo real: accesible a cualquiera con acceso al
          // foro, no solo a quien lo gestiona.
          IconButton(
            icon: const Icon(LucideIcons.barChart2),
            tooltip: 'Ver estadísticas',
            onPressed: () => context.push('/curso/${widget.cursoId}/foro/${widget.foroId}/dashboard'),
          ),
          if (canManageThisForo && _foro != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Editar foro',
              onPressed: () async {
                final saved = await showCreateForoSheet(context, ref, widget.cursoId, existing: _foro);
                if (saved == true) _loadAll();
              },
            ),
            IconButton(
              icon: Icon(_foro!.cerrado ? LucideIcons.lockOpen : LucideIcons.lock),
              tooltip: _foro!.cerrado ? 'Reabrir foro' : 'Cerrar foro',
              onPressed: _toggleEstadoForo,
            ),
          ],
        ],
      ),
      drawer: breakpoint.isCompact ? Drawer(child: SafeArea(child: _sidebar(canCreateForo))) : null,
      body: _loading
          ? const LoadingScreenWidget()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: AppColors.mutedText(context))),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(onPressed: _loadAll, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : Row(
                  children: [
                    if (!breakpoint.isCompact) ...[
                      SizedBox(width: 240, child: _sidebar(canCreateForo)),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(child: _centerColumn(rol, currentUserId, cursoDocenteId)),
                    if (breakpoint.isExpanded) ...[
                      const VerticalDivider(width: 1),
                      SizedBox(width: 240, child: _activityPanel()),
                    ],
                  ],
                ),
    );
  }

  Widget _sidebar(bool canManageForum) {
    return Container(
      color: _isDark ? AppColors.surfaceDark : AppColors.surface2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                const Expanded(child: Text('Foros del curso', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                if (canManageForum)
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 18),
                    tooltip: 'Nuevo foro',
                    onPressed: () async {
                      final created = await showCreateForoSheet(context, ref, widget.cursoId);
                      if (created == true) _loadAll();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _foros.length,
              itemBuilder: (context, i) {
                final f = _foros[i];
                final selected = f.id == widget.foroId;
                return ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: AppColors.primaryLight,
                  leading: Icon(f.cerrado ? LucideIcons.lock : LucideIcons.messageCircle, size: 16),
                  title: Text(f.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  onTap: selected
                      ? () => Navigator.of(context).maybePop()
                      : () {
                          Navigator.of(context).maybePop();
                          context.go('/curso/${widget.cursoId}/foro/${f.id}');
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerColumn(UserRole? rol, String? currentUserId, String? cursoDocenteId) {
    return Column(
      children: [
        Expanded(child: _messagesList(rol, currentUserId, cursoDocenteId)),
        if (_foro?.cerrado == true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: _isDark ? AppColors.surface2Dark : AppColors.neutral100,
            child: Text(
              'Este foro está cerrado. No se pueden enviar nuevos mensajes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _isDark ? AppColors.textMutedDark : AppColors.textMuted, fontSize: 12),
            ),
          )
        else
          _compositor(),
      ],
    );
  }

  /// Encabezado del foro: docente creador, fecha, descripción y adjuntos.
  Widget _foroHeader() {
    final foro = _foro;
    if (foro == null) return const SizedBox.shrink();
    final docente = foro.docente;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surface2Dark : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EdumonAvatar(
                radius: 18,
                imageUrl: docente?.avatarUrl,
                fallbackText: _iniciales(docente),
                semanticLabel: docente?.nombreCompleto,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            docente?.nombreCompleto.isNotEmpty == true ? docente!.nombreCompleto : 'Docente',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _RoleBadge(rol: UserRole.docente, label: 'Creador del foro'),
                      ],
                    ),
                    Text(
                      [
                        if (foro.fechaCreacion != null) 'Publicado ${_relativeTime(foro.fechaCreacion!)}',
                        '${foro.totalMensajes} mensaje${foro.totalMensajes == 1 ? '' : 's'}',
                        if (foro.cerrado) 'Cerrado',
                      ].join(' · '),
                      style: TextStyle(color: AppColors.subtleText(context), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (foro.descripcion != null && foro.descripcion!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(foro.descripcion!, style: const TextStyle(fontSize: 14)),
          ],
          if (foro.archivos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final a in foro.archivos) _ArchivoChip(nombre: a.nombre, tipo: a.tipo)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _messagesList(UserRole? rol, String? currentUserId, String? cursoDocenteId) {
    return RefreshIndicator(
      onRefresh: () => _loadMensajes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _mensajes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _foroHeader(),
                if (_mensajes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Text(
                      'Todavía no hay mensajes. Sé el primero en escribir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedText(context)),
                    ),
                  ),
              ],
            );
          }
          final m = _mensajes[index - 1];
          final replies = _allReplies(m);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mensajeCard(m, rol, currentUserId, cursoDocenteId),
              for (final r in replies)
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: _mensajeCard(r, rol, currentUserId, cursoDocenteId),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }

  Widget _mensajeCard(MensajeForo m, UserRole? rol, String? currentUserId, String? cursoDocenteId) {
    final isOwn = currentUserId != null && currentUserId == m.autorId;
    final foroAbierto = _foro?.cerrado != true;
    // eliminarMensaje real: el autor siempre; el administrador modera los
    // mensajes de su institución; el docente SOLO mensajes de padres y solo
    // en cursos donde él es el docente titular. superadmin no tiene bypass
    // en ese endpoint (le devolvería 403), así que no se le muestra.
    final puedeModerar = rol == UserRole.administrador ||
        (rol == UserRole.docente && m.autor?.rol == UserRole.padreTutor && cursoDocenteId == currentUserId);
    // crearMensaje real: (1) solo se puede responder a un mensaje RAÍZ; (2)
    // un padre solo puede responder a mensajes de docente/administrador.
    final autorEsStaff = m.autor?.rol == UserRole.docente || m.autor?.rol == UserRole.administrador;
    final puedeResponder = m.respuestaA == null && (rol != UserRole.padreTutor || autorEsStaff);
    return _MensajeCard(
      key: ValueKey(m.id),
      mensaje: m,
      liked: m.likedByUser(currentUserId),
      isOwn: isOwn,
      esDocenteDelCurso: m.autorId != null && m.autorId == cursoDocenteId,
      canDelete: isOwn || puedeModerar,
      // actualizarMensaje real: solo el autor, y nunca en un foro cerrado.
      canEdit: isOwn && foroAbierto,
      canReply: foroAbierto && puedeResponder,
      onLike: () => _toggleLike(m),
      onDelete: () => _deleteMensaje(m),
      onReply: () => setState(() => _replyingTo = m),
      onEditSave: (contenido) => _editarMensaje(m.id, contenido),
    );
  }

  Widget _compositor() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _isDark ? AppColors.borderNormalDark : AppColors.borderNormal)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Respondiendo a ${_replyingTo!.autor?.nombreCompleto ?? "mensaje"}',
                      style: TextStyle(fontSize: 11, color: _isDark ? AppColors.textMutedDark : AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 14),
                    tooltip: 'Cancelar respuesta',
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          if (_archivosNuevos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 4,
                children: _archivosNuevos
                    .map(
                      (f) => Chip(
                        label: Text(f.name, style: const TextStyle(fontSize: 10)),
                        onDeleted: () => setState(() => _archivosNuevos.remove(f)),
                      ),
                    )
                    .toList(),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.paperclip),
                tooltip: 'Adjuntar (máx. 5)',
                onPressed: _archivosNuevos.length >= 5 ? null : _pickArchivos,
              ),
              Expanded(
                child: TextField(
                  controller: _compositorController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Escribí un mensaje...', border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.send, color: AppColors.primary),
                tooltip: 'Enviar mensaje',
                onPressed: _sending ? null : _enviarMensaje,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityPanel() {
    final flat = _mensajes.expand((m) => [m, ..._allReplies(m)]).toList();
    final totalRespuestas = flat.where((m) => m.respuestaA != null).length;
    final participantes = <String, MensajeForo>{};
    for (final m in flat) {
      final id = m.autorId;
      if (id != null && !participantes.containsKey(id)) participantes[id] = m;
    }
    final totalArchivos = flat.fold<int>(0, (sum, m) => sum + m.archivos.length);
    final archivosRecientes = flat.expand((m) => m.archivos).toList().reversed.take(8).toList();

    return Container(
      color: _isDark ? AppColors.surfaceDark : AppColors.surface2,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actividad', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            _statRow('Mensajes', flat.length),
            _statRow('Respuestas', totalRespuestas),
            _statRow('Participantes', participantes.length),
            _statRow('Archivos', totalArchivos),
            const SizedBox(height: AppSpacing.md),
            const Text('Participantes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...participantes.values.take(8).map(
                      (m) => EdumonAvatar(
                        radius: 14,
                        imageUrl: m.autor?.avatarUrl,
                        fallbackText: _iniciales(m.autor),
                        semanticLabel: m.autor?.nombreCompleto,
                      ),
                    ),
                if (participantes.length > 8)
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.neutral200,
                    child: Text('+${participantes.length - 8}', style: const TextStyle(fontSize: 10)),
                  ),
              ],
            ),
            if (archivosRecientes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Text('Archivos recientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: AppSpacing.xs),
              ...archivosRecientes.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(LucideIcons.file, size: 14, color: AppColors.mutedText(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(a.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

String _iniciales(ForoAutor? autor) {
  if (autor == null) return '?';
  final n = autor.nombre.trim();
  final a = (autor.apellido ?? '').trim();
  final ini = '${n.isNotEmpty ? n[0] : ''}${a.isNotEmpty ? a[0] : ''}';
  return ini.isEmpty ? '?' : ini.toUpperCase();
}

String _relativeTime(DateTime fecha) {
  final now = DateTime.now();
  final sameDay = now.year == fecha.year && now.month == fecha.month && now.day == fecha.day;
  if (sameDay) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
  final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} $hora';
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.rol, this.label});

  final UserRole? rol;
  final String? label;

  Color _colorFor(UserRole rol) => switch (rol) {
    UserRole.docente => AppColors.primary,
    UserRole.estudiante => AppColors.accent,
    UserRole.padreTutor => AppColors.success,
    UserRole.administrador => AppColors.warningHover,
    UserRole.superAdmin => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final r = rol;
    if (r == null) return const SizedBox.shrink();
    final color = _colorFor(r);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(
        label ?? (r == UserRole.padreTutor ? 'Padre de familia' : r.label),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ArchivoChip extends StatelessWidget {
  const _ArchivoChip({required this.nombre, this.tipo});

  final String nombre;
  final String? tipo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // MensajeForo.js/Foro.js reales: tipo ∈ imagen | video | pdf.
    final icon = switch (tipo) {
      'imagen' => LucideIcons.image,
      'video' => LucideIcons.video,
      'pdf' => LucideIcons.fileText,
      _ => LucideIcons.paperclip,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.mutedText(context)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(nombre, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de mensaje con edición inline propia — BLUEPRINT.md FASE 3.8.3.
class _MensajeCard extends StatefulWidget {
  const _MensajeCard({
    super.key,
    required this.mensaje,
    required this.liked,
    required this.isOwn,
    required this.esDocenteDelCurso,
    required this.canDelete,
    required this.canEdit,
    required this.canReply,
    required this.onLike,
    required this.onDelete,
    required this.onReply,
    required this.onEditSave,
  });

  final MensajeForo mensaje;
  final bool liked;
  final bool isOwn;
  final bool esDocenteDelCurso;
  final bool canDelete;
  final bool canEdit;
  final bool canReply;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final ValueChanged<String> onEditSave;

  @override
  State<_MensajeCard> createState() => _MensajeCardState();
}

class _MensajeCardState extends State<_MensajeCard> {
  bool _editing = false;
  late final TextEditingController _editController = TextEditingController(text: widget.mensaje.contenido);

  void _startEditing() {
    _editController.text = widget.mensaje.contenido;
    setState(() => _editing = true);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mensaje;
    final autor = m.autor;
    final staff = autor?.rol == UserRole.docente || autor?.rol == UserRole.administrador || autor?.rol == UserRole.superAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: staff ? AppColors.primary : Colors.transparent, width: 3)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EdumonAvatar(
                radius: 16,
                imageUrl: autor?.avatarUrl,
                fallbackText: _iniciales(autor),
                semanticLabel: autor?.nombreCompleto,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (autor == null || autor.nombreCompleto.isEmpty)
                                ? 'Usuario eliminado'
                                : '${autor.nombreCompleto}${widget.isOwn ? ' (tú)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RoleBadge(
                          rol: autor?.rol,
                          label: widget.esDocenteDelCurso && autor?.rol == UserRole.docente ? 'Docente del curso' : null,
                        ),
                      ],
                    ),
                    Text(_relativeTime(m.fecha), style: TextStyle(color: AppColors.subtleText(context), fontSize: 11)),
                  ],
                ),
              ),
              if ((widget.canEdit || widget.canDelete) && !_editing)
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.ellipsisVertical, size: 16, color: AppColors.mutedText(context)),
                  tooltip: 'Opciones del mensaje',
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'editar') _startEditing();
                    if (v == 'eliminar') widget.onDelete();
                  },
                  itemBuilder: (context) => [
                    if (widget.canEdit)
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(children: [Icon(LucideIcons.pencil, size: 16), SizedBox(width: 8), Text('Editar')]),
                      ),
                    if (widget.canDelete)
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              widget.isOwn ? 'Eliminar' : 'Eliminar (moderar)',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (_editing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _editController,
                  maxLines: null,
                  maxLength: 1500,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () {
                        final texto = _editController.text.trim();
                        if (texto.isEmpty) return;
                        if (texto != m.contenido) widget.onEditSave(texto);
                        setState(() => _editing = false);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(m.contenido, style: const TextStyle(fontSize: 14)),
          if (m.editado && !_editing)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '(editado)',
                style: TextStyle(color: AppColors.subtleText(context), fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ),
          if (m.archivos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [for (final a in m.archivos) _ArchivoChip(nombre: a.nombre, tipo: a.tipo)],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                onTap: widget.onLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.heart, size: 14, color: widget.liked ? AppColors.secondary : AppColors.mutedText(context)),
                    const SizedBox(width: 2),
                    Text('${m.totalLikes}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                  ],
                ),
              ),
              if (widget.canReply) ...[
                const SizedBox(width: AppSpacing.sm),
                InkWell(
                  onTap: widget.onReply,
                  child: Text('Responder', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
