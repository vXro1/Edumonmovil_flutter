import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/design_system/text/html_lite_view.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/archivos_adjuntos_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../entregas/domain/entities/entrega.dart';
import '../../../entregas/presentation/providers/entregas_providers.dart';
import '../../../entregas/presentation/widgets/calificacion_widgets.dart';
import '../../domain/entities/tarea.dart';
import '../providers/tareas_providers.dart';

/// Detalle de reto Footer condicionado por rol:
/// docente/admin → "Ver entregas"; padre → "Ver mi entrega".
class TareaDetailScreen extends ConsumerStatefulWidget {
  const TareaDetailScreen({super.key, required this.tareaId});

  final String tareaId;

  @override
  ConsumerState<TareaDetailScreen> createState() => _TareaDetailScreenState();
}

class _TareaDetailScreenState extends ConsumerState<TareaDetailScreen> {
  Tarea? _tarea;
  // Solo rol padre: su entrega para este reto (estado, nota, comentario).
  Entrega? _miEntrega;
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
      final esPadre = ref.read(authControllerProvider).user?.rol == UserRole.padreTutor;
      final results = await Future.wait<Object?>([
        ref.read(tareasRepositoryProvider).fetchTareaById(widget.tareaId),
        if (esPadre) ref.read(entregasRepositoryProvider).fetchMiEntrega(widget.tareaId).catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _tarea = results[0] as Tarea;
        _miEntrega = esPadre ? results[1] as Entrega? : null;
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

  // closeTarea y deleteTarea hacen exactamente lo mismo en el backend
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    color: tarea.vencida
                        ? (isDark ? AppColors.error : AppColors.errorHover)
                        : (tarea.cerrada ? AppColors.mutedText(context) : (isDark ? AppColors.green300 : AppColors.green700)),
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
              const SizedBox(height: AppSpacing.sm),
              _MetaReto(tarea: tarea),
              if (!isStaffView) ...[
                const SizedBox(height: AppSpacing.md),
                _MiEstado(entrega: _miEntrega, tarea: tarea),
              ],
              if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Text('Instrucciones', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                HtmlLiteView(html: tarea.descripcion!),
              ],
              if (tarea.etiquetas.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tarea.etiquetas
                      .map((e) => _Badge(text: e, color: AppColors.mutedText(context)))
                      .toList(),
                ),
              ],
              if (tarea.criterios != null && tarea.criterios!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Text('Criterios de evaluación', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                HtmlLiteView(html: tarea.criterios!),
              ],
              if (tarea.archivos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Material del reto (${tarea.archivos.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                ArchivosAdjuntosView(archivos: tarea.archivos),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: EdumonButton(
            label: isStaffView ? 'Ver entregas' : _accionPadre(tarea),
            fullWidth: true,
            size: EdumonButtonSize.lg,
            onPressed: () async {
              final changed = await context.push<bool>(
                isStaffView ? '/tareas/${tarea.id}/entregas' : '/tareas/${tarea.id}/mi-entrega',
              );
              if (changed == true) _load();
            },
          ),
        ),
      ],
    );
  }
}

extension on _TareaDetailScreenState {
  String _accionPadre(Tarea tarea) {
    final e = _miEntrega;
    if (e == null) return tarea.cerrada ? 'Ver reto' : 'Realizar entrega';
    if (e.esBorrador) return 'Continuar mi borrador';
    return e.calificada ? 'Ver calificación y comentario' : 'Ver mi entrega';
  }
}

class _MetaReto extends StatelessWidget {
  const _MetaReto({required this.tarea});

  final Tarea tarea;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedText(context);
    Widget fila(IconData icon, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
    return EdumonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tarea.docenteNombre != null) fila(LucideIcons.user, 'Docente: ${tarea.docenteNombre}'),
          if (tarea.cursoNombre != null) fila(LucideIcons.bookOpen, 'Curso: ${tarea.cursoNombre}'),
          if (tarea.moduloTitulo != null) fila(LucideIcons.layers, 'Módulo: ${tarea.moduloTitulo}'),
          if (tarea.fechaCreacion != null) fila(LucideIcons.calendarPlus, 'Publicado: ${formatFechaHora(tarea.fechaCreacion!)}'),
          if (tarea.fechaEntrega != null)
            fila(
              LucideIcons.calendarClock,
              'Fecha límite: ${formatFechaHora(tarea.fechaEntrega!)}${tarea.cerrada ? '' : ' · ${tiempoRestante(tarea.fechaEntrega!)}'}',
            ),
          fila(LucideIcons.upload, 'Tipo de entrega: ${tarea.tipoEntrega.label}'),
        ],
      ),
    );
  }
}

/// Resumen de la entrega del padre dentro del detalle del reto: estado y,
/// si ya fue calificada, la nota y la retroalimentación del docente.
class _MiEstado extends StatelessWidget {
  const _MiEstado({required this.entrega, required this.tarea});

  final Entrega? entrega;
  final Tarea tarea;

  @override
  Widget build(BuildContext context) {
    final e = entrega;
    if (e?.calificacion != null) return CalificacionCard(calificacion: e!.calificacion!);
    final muted = AppColors.mutedText(context);
    return EdumonCard(
      child: Row(
        children: [
          const Text('Mi entrega: ', style: TextStyle(fontWeight: FontWeight.w700)),
          EstadoEntregaBadge(entrega: e, tarea: tarea),
          if (e != null && !e.esBorrador && e.fechaEnvio != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(formatFechaHora(e.fechaEnvio!), style: TextStyle(color: muted, fontSize: 12), overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
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
