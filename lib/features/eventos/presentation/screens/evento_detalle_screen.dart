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
import '../../../../shared/models/archivo.dart';
import '../../../../shared/widgets/archivos_adjuntos_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../calendario/domain/entities/calendario_entry.dart';
import '../../../entregas/presentation/widgets/calificacion_widgets.dart';
import '../../domain/entities/evento.dart';
import '../providers/eventos_providers.dart';

/// Detalle completo de un evento — se abre al tocarlo en el calendario.
/// Pinta al instante lo que ya trae el item del calendario ([inicial]) y lo
/// completa con getEventoById (docente, cursos, portada, adjunto).
/// getEventoById devuelve 403 a un docente que no creó el evento: en ese
/// caso se muestra lo del calendario en vez de un error.
class EventoDetalleScreen extends ConsumerStatefulWidget {
  const EventoDetalleScreen({super.key, required this.eventoId, this.inicial});

  final String eventoId;
  final CalendarioEntry? inicial;

  @override
  ConsumerState<EventoDetalleScreen> createState() => _EventoDetalleScreenState();
}

class _EventoDetalleScreenState extends ConsumerState<EventoDetalleScreen> {
  Evento? _evento;
  bool _loading = true;
  bool _changed = false;
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
      final evento = await ref.read(eventosRepositoryProvider).fetchEventoById(widget.eventoId);
      if (!mounted) return;
      setState(() {
        _evento = evento;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar el evento.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(authControllerProvider).user?.rol;
    // updateEvento: admin de la institución, o el docente creador (que
    // es el único docente al que getEventoById le responde).
    final canEdit =
        _evento != null && (rol == UserRole.administrador || rol == UserRole.superAdmin || rol == UserRole.docente);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Evento'),
          actions: [
            if (canEdit)
              IconButton(
                icon: const Icon(LucideIcons.pencil),
                tooltip: 'Editar evento',
                onPressed: () async {
                  final changed = await context.push<bool>('/eventos/${widget.eventoId}/editar');
                  if (changed == true) {
                    _changed = true;
                    _load();
                  }
                },
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final e = _evento;
    final ini = widget.inicial;
    if (e == null && ini == null) {
      if (_loading) return const LoadingScreenWidget();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Evento no encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText(context)),
              ),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    // Datos combinados: el detalle real tiene prioridad sobre el calendario.
    final titulo = e?.titulo ?? ini!.titulo;
    final inicio = e?.fechaInicio ?? ini!.fecha;
    final fin = e?.fechaFin ?? ini?.fechaFin;
    final hora = e?.hora ?? ini?.hora;
    final ubicacion = e?.ubicacion ?? ini?.ubicacion;
    final descripcion = e?.descripcion ?? ini?.descripcion;
    final categoria = e?.categoria.label ?? ini?.categoria ?? 'Evento';
    final estado = e?.estado ?? ini?.estado ?? 'programado';
    final cursos = (e?.cursosNombres.isNotEmpty ?? false) ? e!.cursosNombres : (ini?.cursosNombres ?? const <String>[]);
    final muted = AppColors.mutedText(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final estadoColor = switch (estado) {
      'cancelado' => isDark ? AppColors.error : AppColors.errorHover,
      'finalizado' => muted,
      'en_curso' => isDark ? AppColors.green300 : AppColors.green700,
      _ => isDark ? AppColors.blue300 : AppColors.blue700,
    };
    final estadoLabel = switch (estado) {
      'en_curso' => 'En curso',
      'finalizado' => 'Finalizado',
      'cancelado' => 'Cancelado',
      _ => 'Programado',
    };

    Widget fila(IconData icon, String titulo, String valor) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: '$titulo: $valor',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: isDark ? AppColors.blue300 : AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(color: muted, fontSize: 12)),
                  Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final mismoDia = fin == null || (fin.year == inicio.year && fin.month == inicio.month && fin.day == inicio.day);
    final cuando = fin == null
        ? formatFechaHora(inicio)
        : mismoDia
        ? '${formatFechaHora(inicio)} – ${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}'
        : '${formatFechaHora(inicio)}\nhasta ${formatFechaHora(fin)}';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (e?.imagenPortadaUrl != null) ...[
            ArchivosAdjuntosView(
              archivos: [
                Archivo(id: 'portada', url: e!.imagenPortadaUrl!, nombre: 'Portada del evento', tipo: 'imagen'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _Chip(texto: categoria, color: isDark ? AppColors.purple300 : AppColors.purple700, icon: LucideIcons.tag),
              _Chip(texto: estadoLabel, color: estadoColor, icon: LucideIcons.circleDot),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(decoration: estado == 'cancelado' ? TextDecoration.lineThrough : null),
          ),
          if (estado == 'cancelado')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Este evento fue cancelado.',
                style: TextStyle(color: estadoColor, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          EdumonCard(
            child: Column(
              children: [
                fila(LucideIcons.calendarDays, 'Cuándo', cuando),
                if (hora != null && hora.isNotEmpty) fila(LucideIcons.clock, 'Hora', hora),
                if (ubicacion != null && ubicacion.isNotEmpty) fila(LucideIcons.mapPin, 'Lugar', ubicacion),
                if (e?.docenteNombre != null) fila(LucideIcons.user, 'Organiza', e!.docenteNombre!),
                if (cursos.isNotEmpty)
                  fila(LucideIcons.bookOpen, cursos.length == 1 ? 'Curso' : 'Cursos', cursos.join(', ')),
                if (e?.fechaCreacion != null)
                  fila(LucideIcons.calendarPlus, 'Publicado', formatFechaHora(e!.fechaCreacion!)),
              ],
            ),
          ),
          if (descripcion != null && descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(descripcion.trim(), style: const TextStyle(fontSize: 15, height: 1.45)),
          ],
          if (e?.adjunto != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Text('Archivo adjunto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.xs),
            ArchivosAdjuntosView(archivos: [e!.adjunto!]),
          ],
          if (_loading && e == null)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.color, required this.icon});

  final String texto;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
