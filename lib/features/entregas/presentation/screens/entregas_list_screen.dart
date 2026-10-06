import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/archivos_adjuntos_view.dart';
import '../../domain/entities/entrega.dart';
import '../providers/entregas_providers.dart';
import '../widgets/calificacion_widgets.dart';

String _iniciales(EntregaPadre? p) {
  if (p == null) return '?';
  final ini = '${p.nombre.isNotEmpty ? p.nombre[0] : ''}${(p.apellido ?? '').isNotEmpty ? p.apellido![0] : ''}';
  return ini.isEmpty ? '?' : ini.toUpperCase();
}

enum _Filtro { todas, porCalificar, calificadas }

/// Entregas de un reto (vista docente)
/// Tocar una entrega abre la revisión completa (lo que entregó el padre +
/// calificación por estrellas + retroalimentación).
class EntregasListScreen extends ConsumerStatefulWidget {
  const EntregasListScreen({super.key, required this.tareaId});

  final String tareaId;

  @override
  ConsumerState<EntregasListScreen> createState() => _EntregasListScreenState();
}

class _EntregasListScreenState extends ConsumerState<EntregasListScreen> {
  List<Entrega> _items = const [];
  EntregasEstadisticas _stats = const EntregasEstadisticas();
  _Filtro _filtro = _Filtro.todas;
  bool _loading = true;
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
      final result = await ref.read(entregasRepositoryProvider).fetchEntregasPorTarea(widget.tareaId);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _stats = result.stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar las entregas.';
      });
    }
  }

  Future<void> _abrir(Entrega entrega) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RevisarEntregaScreen(entrega: entrega)),
    );
    if (changed == true) _load();
  }

  List<Entrega> get _filtradas => switch (_filtro) {
    _Filtro.todas => _items,
    _Filtro.porCalificar => _items.where((e) => !e.calificada).toList(),
    _Filtro.calificadas => _items.where((e) => e.calificada).toList(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entregas del reto')),
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
                    TextButton(onPressed: _load, child: const Text('Reintentar')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Row(
                    children: [
                      _StatChip(label: 'Recibidas', value: _stats.total),
                      const SizedBox(width: AppSpacing.xs),
                      _StatChip(label: 'A tiempo', value: _stats.enviadas),
                      const SizedBox(width: AppSpacing.xs),
                      _StatChip(label: 'Tarde', value: _stats.tarde),
                      const SizedBox(width: AppSpacing.xs),
                      _StatChip(label: 'Calificadas', value: _stats.valoradas),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<_Filtro>(
                    segments: [
                      const ButtonSegment(value: _Filtro.todas, label: Text('Todas')),
                      ButtonSegment(
                        value: _Filtro.porCalificar,
                        label: Text('Por calificar (${_items.where((e) => !e.calificada).length})'),
                      ),
                      const ButtonSegment(value: _Filtro.calificadas, label: Text('Calificadas')),
                    ],
                    selected: {_filtro},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _filtro = s.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_filtradas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(
                        child: Text(
                          _items.isEmpty ? 'Todavía no hay entregas enviadas.' : 'No hay entregas en este filtro.',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      ),
                    )
                  else
                    for (final entrega in _filtradas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _EntregaResumenCard(entrega: entrega, onTap: () => _abrir(entrega)),
                      ),
                ],
              ),
            ),
    );
  }
}

class _EntregaResumenCard extends StatelessWidget {
  const _EntregaResumenCard({required this.entrega, required this.onTap});

  final Entrega entrega;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedText(context);
    final nAdjuntos = entrega.archivos.length + entrega.enlaces.length;
    return Semantics(
      button: true,
      label: '${entrega.padre?.nombreCompleto ?? 'Participante'}, ${entrega.estadoLabel}. Toca para revisar',
      excludeSemantics: true,
      child: EdumonCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EdumonAvatar(radius: 20, imageUrl: entrega.padre?.avatarUrl, fallbackText: _iniciales(entrega.padre)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entrega.padre?.nombreCompleto ?? 'Participante', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (entrega.fechaEnvio != null)
                    Text('Enviada: ${formatFechaHora(entrega.fechaEnvio!)}', style: TextStyle(color: muted, fontSize: 12)),
                  if (entrega.textoRespuesta?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(entrega.textoRespuesta!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (nAdjuntos > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.paperclip, size: 14, color: muted),
                          const SizedBox(width: 4),
                          Text('$nAdjuntos adjunto${nAdjuntos == 1 ? '' : 's'}', style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      EstadoEntregaBadge(entrega: entrega),
                      if (entrega.calificacion != null) EstrellasView(valoracion: entrega.calificacion!.valoracion, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: muted),
          ],
        ),
      ),
    );
  }
}

/// Revisión de una entrega (docente): todo lo que envió el padre y el
/// formulario de calificación. calificarEntrega: valoracion entera 1-5 +
/// comentario (retroalimentación, máx. 1000); se puede recalificar.
class RevisarEntregaScreen extends ConsumerStatefulWidget {
  const RevisarEntregaScreen({super.key, required this.entrega});

  final Entrega entrega;

  @override
  ConsumerState<RevisarEntregaScreen> createState() => _RevisarEntregaScreenState();
}

class _RevisarEntregaScreenState extends ConsumerState<RevisarEntregaScreen> {
  late int _valoracion = widget.entrega.calificacion?.valoracion ?? 0;
  late final _comentarioController = TextEditingController(text: widget.entrega.calificacion?.comentario ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_valoracion < 1) {
      setState(() => _error = 'Selecciona de 1 a 5 estrellas.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(entregasRepositoryProvider).calificarEntrega(
        id: widget.entrega.id,
        valoracion: _valoracion,
        comentario: _comentarioController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.entrega.calificada ? 'Calificación actualizada.' : 'Entrega calificada. Se notificó al padre de familia.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is AppException ? e.message : 'No se pudo guardar la calificación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entrega;
    final muted = AppColors.mutedText(context);
    final adjuntos = [...e.archivos, ...e.enlaces];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar entrega')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          EdumonCard(
            child: Row(
              children: [
                EdumonAvatar(radius: 24, imageUrl: e.padre?.avatarUrl, fallbackText: _iniciales(e.padre)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.padre?.nombreCompleto ?? 'Participante', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (e.padre?.correo != null) Text(e.padre!.correo!, style: TextStyle(color: muted, fontSize: 12)),
                      if (e.fechaEnvio != null) Text('Enviada: ${formatFechaHora(e.fechaEnvio!)}', style: TextStyle(color: muted, fontSize: 12)),
                      const SizedBox(height: 6),
                      EstadoEntregaBadge(entrega: e),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EdumonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Respuesta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: AppSpacing.sm),
                if (e.textoRespuesta?.trim().isNotEmpty ?? false)
                  SelectableText(e.textoRespuesta!.trim(), style: const TextStyle(fontSize: 15, height: 1.4))
                else
                  Text('Sin texto de respuesta.', style: TextStyle(color: muted, fontStyle: FontStyle.italic)),
                if (adjuntos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Adjuntos (${adjuntos.length})', style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: AppSpacing.xs),
                  ArchivosAdjuntosView(archivos: adjuntos),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EdumonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  e.calificada ? 'Actualizar calificación' : 'Calificar',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Semantics(
                    label: 'Calificación: $_valoracion de 5 estrellas',
                    child: RatingBar.builder(
                      initialRating: _valoracion.toDouble(),
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 44,
                      glow: false,
                      unratedColor: isDark ? AppColors.neutral600 : AppColors.neutral300,
                      itemBuilder: (context, _) =>
                          Icon(Icons.star_rounded, color: isDark ? AppColors.yellow400 : AppColors.yellow600),
                      onRatingUpdate: (r) => setState(() {
                        _valoracion = r.round();
                        _error = null;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _valoracion == 0 ? 'Toca las estrellas para calificar' : '$_valoracion/5 · ${Calificacion.etiquetas[_valoracion]}',
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                EdumonTextField(
                  controller: _comentarioController,
                  label: 'Retroalimentación para el padre de familia',
                  hint: '¿Qué hizo bien? ¿Qué puede mejorar?',
                  minLines: 3,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: TextStyle(color: isDark ? AppColors.error : AppColors.errorHover)),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                EdumonButton(
                  label: e.calificada ? 'Actualizar calificación' : 'Guardar calificación',
                  leftIcon: LucideIcons.award,
                  fullWidth: true,
                  size: EdumonButtonSize.lg,
                  loading: _saving,
                  onPressed: _saving ? null : _guardar,
                ),
                if (e.calificacion != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [
                      'Calificada',
                      if (e.calificacion!.docenteNombre != null) 'por ${e.calificacion!.docenteNombre}',
                      if (e.calificacion!.fechaCalificacion != null) 'el ${formatFechaHora(e.calificacion!.fechaCalificacion!)}',
                    ].join(' '),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: EdumonCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: Column(
          children: [
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: TextStyle(color: AppColors.mutedText(context), fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
