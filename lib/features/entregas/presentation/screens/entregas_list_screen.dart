import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entrega.dart';
import '../providers/entregas_providers.dart';

Color _estadoColor(BuildContext context, String estado) {
  switch (estado) {
    case 'calificada':
      return AppColors.success;
    case 'enviada':
      return AppColors.accent;
    case 'tarde':
      return AppColors.warning;
    default:
      return AppColors.mutedText(context);
  }
}

/// Entregas de un reto (vista docente) — BLUEPRINT.md FASE 3.4.5.
class EntregasListScreen extends ConsumerStatefulWidget {
  const EntregasListScreen({super.key, required this.tareaId});

  final String tareaId;

  @override
  ConsumerState<EntregasListScreen> createState() => _EntregasListScreenState();
}

class _EntregasListScreenState extends ConsumerState<EntregasListScreen> {
  List<Entrega> _items = const [];
  EntregasEstadisticas _stats = const EntregasEstadisticas();
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

  Future<void> _calificar(Entrega entrega) async {
    var valoracion = entrega.calificacion?.valoracion ?? 0;
    final comentarioController = TextEditingController(text: entrega.calificacion?.comentario);
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
                Text(
                  'Calificar a ${entrega.padre?.nombreCompleto ?? "participante"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Center(
                  child: RatingBar.builder(
                    initialRating: valoracion.toDouble(),
                    minRating: 1,
                    itemCount: 5,
                    itemSize: 40,
                    itemBuilder: (context, _) => const Icon(Icons.star, color: AppColors.warning),
                    onRatingUpdate: (rating) => valoracion = rating.round(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                EdumonTextField(controller: comentarioController, label: 'Comentario (opcional)'),
                const SizedBox(height: AppSpacing.sm),
                EdumonButton(
                  label: 'Guardar calificación',
                  fullWidth: true,
                  onPressed: () async {
                    if (valoracion < 1) {
                      setSheetState(() => error = 'Seleccioná al menos 1 estrella.');
                      return;
                    }
                    try {
                      await ref
                          .read(entregasRepositoryProvider)
                          .calificarEntrega(id: entrega.id, valoracion: valoracion, comentario: comentarioController.text.trim());
                      if (context.mounted) Navigator.of(context).pop(true);
                    } catch (e) {
                      setSheetState(() => error = e is AppException ? e.message : 'No se pudo calificar.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entregas')),
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
                          _StatChip(label: 'Total', value: _stats.total),
                          const SizedBox(width: AppSpacing.xs),
                          _StatChip(label: 'Enviadas', value: _stats.enviadas),
                          const SizedBox(width: AppSpacing.xs),
                          _StatChip(label: 'Tarde', value: _stats.tarde),
                          const SizedBox(width: AppSpacing.xs),
                          _StatChip(label: 'Calificadas', value: _stats.valoradas),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(child: Text('Todavía no hay entregas.', style: TextStyle(color: AppColors.mutedText(context)))),
                        )
                      else
                        ..._items.map((entrega) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: EdumonCard(
                              onTap: () => _calificar(entrega),
                              child: Row(
                                children: [
                                  EdumonAvatar(
                                    radius: 18,
                                    imageUrl: entrega.padre?.avatarUrl,
                                    fallbackText: entrega.padre?.nombre.isNotEmpty == true
                                        ? entrega.padre!.nombre[0].toUpperCase()
                                        : '?',
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entrega.padre?.nombreCompleto ?? 'Participante', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (entrega.textoRespuesta != null && entrega.textoRespuesta!.isNotEmpty)
                                          Text(entrega.textoRespuesta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                                        if (entrega.calificacion != null)
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star,
                                                size: 14,
                                                color: i < entrega.calificacion!.valoracion ? AppColors.warning : AppColors.neutral200,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _estadoColor(context, entrega.estado).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      entrega.estado,
                                      style: TextStyle(color: _estadoColor(context, entrega.estado), fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
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
            Text(label, style: TextStyle(color: AppColors.mutedText(context), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
