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
import '../widgets/calificacion_widgets.dart';

class _Item {
  const _Item({required this.tarea, required this.entrega});
  final Tarea tarea;
  final Entrega? entrega;

  bool get pendiente => entrega == null || entrega!.esBorrador;
}

enum _Filtro { todas, pendientes, entregadas, calificadas }

class MisEntregasScreen extends ConsumerStatefulWidget {
  const MisEntregasScreen({super.key});

  @override
  ConsumerState<MisEntregasScreen> createState() => _MisEntregasScreenState();
}

class _MisEntregasScreenState extends ConsumerState<MisEntregasScreen> {
  List<_Item> _items = const [];
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
      final tareasPage = await ref.read(tareasRepositoryProvider).fetchTareas(page: 1, limit: 50);
      final entregasRepo = ref.read(entregasRepositoryProvider);
      final entregas = await Future.wait(tareasPage.items.map((t) => entregasRepo.fetchMiEntrega(t.id)));
      final items = [for (var i = 0; i < tareasPage.items.length; i++) _Item(tarea: tareasPage.items[i], entrega: entregas[i])];
      // Primero lo que requiere acción (pendientes por fecha límite), luego el resto.
      items.sort((a, b) {
        if (a.pendiente != b.pendiente) return a.pendiente ? -1 : 1;
        final fa = a.tarea.fechaEntrega ?? DateTime(2100);
        final fb = b.tarea.fechaEntrega ?? DateTime(2100);
        return a.pendiente ? fa.compareTo(fb) : fb.compareTo(fa);
      });
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

  List<_Item> get _filtrados => switch (_filtro) {
    _Filtro.todas => _items,
    _Filtro.pendientes => _items.where((i) => i.pendiente).toList(),
    _Filtro.entregadas => _items.where((i) => !i.pendiente && !i.entrega!.calificada).toList(),
    _Filtro.calificadas => _items.where((i) => i.entrega?.calificada ?? false).toList(),
  };

  Future<void> _abrir(_Item item) async {
    final changed = await context.push<bool>('/tareas/${item.tarea.id}/mi-entrega');
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis entregas')),
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
      return Center(child: Text('Todavía no tienes retos asignados.', style: TextStyle(color: AppColors.mutedText(context))));
    }

    final pendientes = _items.where((i) => i.pendiente).length;
    final calificadas = _items.where((i) => i.entrega?.calificada ?? false).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (f, label) in [
                  (_Filtro.todas, 'Todas (${_items.length})'),
                  (_Filtro.pendientes, 'Pendientes ($pendientes)'),
                  (_Filtro.entregadas, 'En revisión'),
                  (_Filtro.calificadas, 'Calificadas ($calificadas)'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filtro == f,
                      onSelected: (_) => setState(() => _filtro = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: Text('No hay retos en este filtro.', style: TextStyle(color: AppColors.mutedText(context)))),
            )
          else
            for (final item in _filtrados)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _EntregaCard(item: item, onTap: () => _abrir(item)),
              ),
        ],
      ),
    );
  }
}

class _EntregaCard extends StatelessWidget {
  const _EntregaCard({required this.item, required this.onTap});

  final _Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tarea = item.tarea;
    final entrega = item.entrega;
    final muted = AppColors.mutedText(context);
    final calificacion = entrega?.calificacion;
    final accion = item.pendiente
        ? (tarea.cerrada ? 'Ver reto' : (entrega == null ? 'Realizar entrega' : 'Continuar borrador'))
        : (calificacion != null ? 'Ver calificación y comentario' : 'Ver mi entrega');

    return Semantics(
      button: true,
      label: '${tarea.titulo}. ${estadoEntregaVisual(context, entrega, tarea).label}'
          '${calificacion != null ? '. ${calificacion.valoracion} de 5 estrellas' : ''}. $accion',
      excludeSemantics: true,
      child: EdumonCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EstadoEntregaBadge(entrega: entrega, tarea: tarea),
            const SizedBox(height: AppSpacing.xs),
            Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (tarea.cursoNombre != null) Text(tarea.cursoNombre!, style: TextStyle(color: muted, fontSize: 12)),
            if (tarea.fechaEntrega != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item.pendiente
                      ? '${formatFechaHora(tarea.fechaEntrega!)} · ${tiempoRestante(tarea.fechaEntrega!)}'
                      : 'Enviada: ${entrega!.fechaEnvio != null ? formatFechaHora(entrega.fechaEnvio!) : '—'}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
            if (calificacion != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  EstrellasView(valoracion: calificacion.valoracion, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${calificacion.valoracion}/5 · ${calificacion.etiqueta}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              if (calificacion.tieneComentario) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.messageSquareQuote, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        calificacion.comentario!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(accion, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
