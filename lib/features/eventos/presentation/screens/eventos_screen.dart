import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/evento.dart';
import '../providers/eventos_providers.dart';

/// Eventos (gestión completa) — BLUEPRINT.md FASE 3.6. Ruta /eventos
/// (docente/admin). El toggle lista/calendario de la web no está completo
/// ahí tampoco — se implementa solo la vista lista acá.
class EventosScreen extends ConsumerStatefulWidget {
  const EventosScreen({super.key});

  @override
  ConsumerState<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends ConsumerState<EventosScreen> {
  List<Evento> _items = const [];
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
      final items = await ref.read(eventosRepositoryProvider).fetchEventos();
      if (!mounted) return;
      setState(() {
        _items = items..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los eventos.';
      });
    }
  }

  Future<void> _delete(Evento evento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Eliminar "${evento.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(eventosRepositoryProvider).deleteEvento(evento.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo eliminar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(authControllerProvider).user?.rol;
    final canManage = rol == UserRole.docente || rol == UserRole.administrador || rol == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>('/eventos/nuevo');
                if (created == true) _load();
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: _buildBody(canManage),
    );
  }

  Widget _buildBody(bool canManage) {
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
      return Center(
        child: Text('Todavía no hay eventos. Creá el primero.', style: TextStyle(color: AppColors.mutedText(context))),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final evento = _items[index];
          return EdumonCard(
            onTap: canManage
                ? () async {
                    final updated = await context.push<bool>('/eventos/${evento.id}/editar');
                    if (updated == true) _load();
                  }
                : null,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.sectionCalendario.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(LucideIcons.calendarDays, color: AppColors.sectionCalendario),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(
                        '${_formatFecha(evento.fechaInicio)}${evento.ubicacion != null ? ' · ${evento.ubicacion}' : ''}',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          evento.categoria.label,
                          style: const TextStyle(color: AppColors.accentHover, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                    tooltip: 'Eliminar evento',
                    onPressed: () => _delete(evento),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}
