import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/calendario_entry.dart';

/// Item de un día del calendario (global y por curso). Tocarlo abre el
/// detalle completo: evento → /eventos/:id, reto → /tareas/:id.
class CalendarioEntryTile extends StatelessWidget {
  const CalendarioEntryTile({super.key, required this.entry, this.onChanged});

  final CalendarioEntry entry;

  /// Se llama al volver del detalle si hubo cambios (ej. evento editado).
  final VoidCallback? onChanged;

  String _hhmm(DateTime f) => '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final esTarea = entry.tipo == CalendarioEntryTipo.tarea;
    final color = esTarea ? AppColors.sectionTareas : AppColors.sectionCalendario;
    final muted = AppColors.mutedText(context);
    final cancelado = entry.estado == 'cancelado';

    final tipoLabel = esTarea ? (entry.vencida ? 'Reto vencido' : 'Reto') : (entry.categoria ?? 'Evento');
    final hora = esTarea
        ? 'Entrega hasta ${_hhmm(entry.fecha)}'
        : (entry.hora?.isNotEmpty == true ? entry.hora! : _hhmm(entry.fecha)) +
              (entry.fechaFin != null ? ' – ${_hhmm(entry.fechaFin!)}' : '');
    final detalles = [
      hora,
      if (!esTarea && entry.ubicacion != null) entry.ubicacion!,
      if (entry.cursosNombres.isNotEmpty) entry.cursosNombres.join(', ') else ?entry.cursoNombre,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label:
            '$tipoLabel: ${entry.titulo}. ${detalles.join('. ')}${cancelado ? '. Cancelado' : ''}. Toca para ver el detalle',
        excludeSemantics: true,
        child: EdumonCard(
          onTap: () async {
            final changed = await context.push<bool>(
              esTarea ? '/tareas/${entry.id}' : '/eventos/${entry.id}',
              extra: esTarea ? null : entry,
            );
            if (changed == true) onChanged?.call();
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(esTarea ? LucideIcons.target : LucideIcons.calendarDays, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipoLabel.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                    ),
                    Text(
                      entry.titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: cancelado ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    for (final d in detalles)
                      Text(
                        d,
                        style: TextStyle(color: muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (cancelado)
                      const Text(
                        'Cancelado',
                        style: TextStyle(color: AppColors.errorHover, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
