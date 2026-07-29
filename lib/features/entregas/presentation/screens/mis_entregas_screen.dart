import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tareas/domain/entities/tarea.dart';
import '../../../tareas/presentation/providers/tareas_providers.dart';
import '../../domain/entities/entrega.dart';
import '../providers/entregas_providers.dart';

class _Item {
  const _Item({required this.tarea, required this.entrega});
  final Tarea tarea;
  final Entrega? entrega;
}

/// Entregas (rol padre) — BLUEPRINT.md FASE 3.7.4.
/// (⚠️) El blueprint documenta GET /entregas/padre/:padreId como endpoint
/// agregado, pero entregaController.js real (ya verificado en otras
/// pantallas) solo expone getEntregasByPadreAndTarea, escaneado por tarea —
/// no existe un listado global. Se arma acá combinando fetchTareas (ya
/// scopeado al padre por el backend) + fetchMiEntrega por cada una, en vez
/// de llamar a un endpoint que no está confirmado.
class MisEntregasScreen extends ConsumerStatefulWidget {
  const MisEntregasScreen({super.key});

  @override
  ConsumerState<MisEntregasScreen> createState() => _MisEntregasScreenState();
}

class _MisEntregasScreenState extends ConsumerState<MisEntregasScreen> {
  List<_Item> _items = const [];
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
      final tareasPage = await ref.read(tareasRepositoryProvider).fetchTareas(page: 1, limit: 100);
      final entregasRepo = ref.read(entregasRepositoryProvider);
      final items = <_Item>[];
      for (final tarea in tareasPage.items) {
        final entrega = await entregasRepo.fetchMiEntrega(tarea.id);
        items.add(_Item(tarea: tarea, entrega: entrega));
      }
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _enviar(Entrega entrega) async {
    try {
      await ref.read(entregasRepositoryProvider).enviarEntrega(entrega.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo enviar la entrega.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entregas')),
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
      return Center(child: Text('Todavía no tenés retos asignados.', style: TextStyle(color: AppColors.mutedText(context))));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _EntregaCard(item: _items[index], onEnviar: _enviar, onChanged: _load),
      ),
    );
  }
}

class _EntregaCard extends StatelessWidget {
  const _EntregaCard({required this.item, required this.onEnviar, required this.onChanged});

  final _Item item;
  final ValueChanged<Entrega> onEnviar;
  final VoidCallback onChanged;

  Color _estadoColor(BuildContext context, String? estado) {
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

  @override
  Widget build(BuildContext context) {
    final tarea = item.tarea;
    final entrega = item.entrega;
    final canEdit = entrega == null || entrega.esBorrador;
    final canSend = entrega != null && entrega.esBorrador;
    final estadoLabel = entrega?.estado ?? 'sin entregar';

    return EdumonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _estadoColor(context, entrega?.estado).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  estadoLabel,
                  style: TextStyle(color: _estadoColor(context, entrega?.estado), fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (tarea.cursoNombre != null)
            Text(tarea.cursoNombre!, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
          if (entrega?.textoRespuesta != null && entrega!.textoRespuesta!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(entrega.textoRespuesta!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (entrega?.calificacion != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 14,
                      color: i < entrega!.calificacion!.valoracion ? AppColors.warning : AppColors.neutral200,
                    ),
                  ),
                ),
                if (entrega!.calificacion!.comentario != null && entrega.calificacion!.comentario!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      entrega.calificacion!.comentario!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (canEdit)
                TextButton.icon(
                  onPressed: () async {
                    final changed = await context.push<bool>('/tareas/${tarea.id}/mi-entrega');
                    if (changed == true) onChanged();
                  },
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: Text(entrega == null ? 'Realizar' : 'Editar borrador'),
                ),
              if (canSend)
                TextButton.icon(
                  onPressed: () => onEnviar(entrega),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Enviar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
