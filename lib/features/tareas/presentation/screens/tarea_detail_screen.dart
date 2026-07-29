import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/tarea.dart';
import '../providers/tareas_providers.dart';

/// Detalle de reto — BLUEPRINT.md FASE 3.4.4. Footer condicionado por rol:
/// docente/admin → "Ver entregas"; padre → "Ver mi entrega".
class TareaDetailScreen extends ConsumerStatefulWidget {
  const TareaDetailScreen({super.key, required this.tareaId});

  final String tareaId;

  @override
  ConsumerState<TareaDetailScreen> createState() => _TareaDetailScreenState();
}

class _TareaDetailScreenState extends ConsumerState<TareaDetailScreen> {
  Tarea? _tarea;
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
      final tarea = await ref.read(tareasRepositoryProvider).fetchTareaById(widget.tareaId);
      if (!mounted) return;
      setState(() {
        _tarea = tarea;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar el reto.';
      });
    }
  }

  // closeTarea y deleteTarea reales hacen exactamente lo mismo en el backend
  // (estado:'cerrada'), no hay borrado real — se deja una sola acción "Cerrar
  // reto" en vez de dos que sugerirían comportamientos distintos.
  Future<void> _cerrar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar reto'),
        content: const Text('¿Cerrar este reto? Ya no se van a poder crear nuevas entregas.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar reto')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(tareasRepositoryProvider).cerrarTarea(widget.tareaId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo cerrar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(authControllerProvider).user?.rol;
    // Editar/cerrar el reto: solo Docente (y superAdmin) — contenido
    // pedagógico, Administrador solo visualiza.
    final canManage = rol == UserRole.docente || rol == UserRole.superAdmin;
    // "Ver entregas" (todas) vs "Ver mi entrega" (propia, solo padre/tutor):
    // esto es visibilidad de staff, no permiso de edición — Administrador
    // sigue viendo todas las entregas igual que Docente.
    final isStaffView = rol == UserRole.docente || rol == UserRole.administrador || rol == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reto'),
        actions: [
          if (canManage && _tarea != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Editar',
              onPressed: () async {
                final changed = await context.push<bool>('/cursos/${_tarea!.cursoId}/tareas/${_tarea!.id}/editar');
                if (changed == true) _load();
              },
            ),
            if (!_tarea!.cerrada)
              IconButton(icon: const Icon(LucideIcons.lock), tooltip: 'Cerrar reto', onPressed: _cerrar),
          ],
        ],
      ),
      body: _buildBody(isStaffView),
    );
  }

  Widget _buildBody(bool isStaffView) {
    if (_loading) return const LoadingScreenWidget();

    if (_error != null || _tarea == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Reto no encontrado.', style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final tarea = _tarea!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _Badge(
                    text: tarea.vencida ? 'Vencida' : (tarea.cerrada ? 'Cerrada' : 'Activa'),
                    color: tarea.vencida ? AppColors.error : (tarea.cerrada ? AppColors.mutedText(context) : AppColors.success),
                  ),
                  _Badge(
                    text: tarea.asignacionTipo == AsignacionTipo.todos ? 'Para todos' : 'Seleccionados',
                    color: AppColors.accent,
                  ),
                  _Badge(text: tarea.tipoEntrega.label, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(tarea.titulo, style: Theme.of(context).textTheme.headlineSmall),
              if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(tarea.descripcion!),
              ],
              if (tarea.fechaEntrega != null) ...[
                const SizedBox(height: AppSpacing.md),
                EdumonCard(
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 18, color: AppColors.mutedText(context)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Entrega: ${tarea.fechaEntrega!.day}/${tarea.fechaEntrega!.month}/${tarea.fechaEntrega!.year} ${tarea.fechaEntrega!.hour.toString().padLeft(2, '0')}:${tarea.fechaEntrega!.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                ),
              ],
              if (tarea.archivos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Text('Archivos', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                ...tarea.archivos.map((a) => EdumonCard(
                      child: Row(
                        children: [
                          Icon(LucideIcons.file, size: 18, color: AppColors.mutedText(context)),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: Text(a.nombre, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: EdumonButton(
            label: isStaffView ? 'Ver entregas' : 'Ver mi entrega',
            fullWidth: true,
            size: EdumonButtonSize.lg,
            onPressed: () => context.push(isStaffView ? '/tareas/${tarea.id}/entregas' : '/tareas/${tarea.id}/mi-entrega'),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
