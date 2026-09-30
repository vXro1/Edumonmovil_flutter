import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tareas/domain/entities/tarea.dart';
import '../../domain/entities/entrega.dart';

const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "12 sep 2026, 14:30" — fecha legible sin depender de la inicialización de
/// locales de intl.
String formatFechaHora(DateTime f) =>
    '${f.day} ${_meses[f.month - 1]} ${f.year}, ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

/// "Vence en 3 días" / "Venció hace 2 horas" relativo a ahora.
String tiempoRestante(DateTime limite) {
  final diff = limite.difference(DateTime.now());
  final pasado = diff.isNegative;
  final d = diff.abs();
  final texto = d.inDays >= 1
      ? '${d.inDays} día${d.inDays == 1 ? '' : 's'}'
      : d.inHours >= 1
      ? '${d.inHours} hora${d.inHours == 1 ? '' : 's'}'
      : '${d.inMinutes} min';
  return pasado ? 'Venció hace $texto' : 'Vence en $texto';
}

Color _estrellaLlena(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? AppColors.yellow400 : AppColors.yellow600;

Color _estrellaVacia(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? AppColors.neutral600 : AppColors.neutral300;

/// Estrellas de solo lectura, con etiqueta accesible "4 de 5 estrellas".
class EstrellasView extends StatelessWidget {
  const EstrellasView({super.key, required this.valoracion, this.size = 18});

  final int valoracion;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$valoracion de 5 estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(
            i < valoracion ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < valoracion ? _estrellaLlena(context) : _estrellaVacia(context),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de calificación que ve el padre: estrellas, etiqueta, la
/// retroalimentación escrita del docente, quién calificó y cuándo.
class CalificacionCard extends StatelessWidget {
  const CalificacionCard({super.key, required this.calificacion});

  final Calificacion calificacion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = calificacion;
    final acento = isDark ? AppColors.green300 : AppColors.green700;
    final fecha = c.fechaUltimaModificacion ?? c.fechaCalificacion;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(acento.withValues(alpha: isDark ? 0.12 : 0.06), isDark ? AppColors.surfaceDark : AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: acento.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.award, color: acento, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('Calificación del docente', style: TextStyle(color: acento, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: 4,
            children: [
              EstrellasView(valoracion: c.valoracion, size: 30),
              Text('${c.valoracion}/5', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              if (c.etiqueta.isNotEmpty)
                Text(c.etiqueta, style: TextStyle(color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Retroalimentación', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.mutedText(context), fontSize: 13)),
          const SizedBox(height: 4),
          if (c.tieneComentario)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface2Dark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border(left: BorderSide(color: acento, width: 3)),
              ),
              child: Text(c.comentario!.trim(), style: const TextStyle(fontSize: 15, height: 1.4)),
            )
          else
            Text(
              'El docente no dejó comentarios.',
              style: TextStyle(color: AppColors.mutedText(context), fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (c.docenteNombre != null) 'Por ${c.docenteNombre}',
              if (fecha != null) formatFechaHora(fecha),
            ].join(' · '),
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
          ),
          if (c.valoracionAnterior != null && c.valoracionAnterior != c.valoracion)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Calificación actualizada (antes ${c.valoracionAnterior}/5)',
                style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Estado de la entrega del padre para un reto, legible y con color.
({String label, IconData icon, Color color}) estadoEntregaVisual(BuildContext context, Entrega? entrega, Tarea? tarea) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  Color c(Color light, Color dark) => isDark ? dark : light;
  if (entrega == null || entrega.esBorrador) {
    final vencida = tarea != null && (tarea.vencida || tarea.cerrada);
    if (vencida) {
      return (label: tarea.cerrada ? 'Reto cerrado' : 'Vencido sin entregar', icon: LucideIcons.circleAlert, color: c(AppColors.errorHover, AppColors.error));
    }
    if (entrega != null) return (label: 'Borrador sin enviar', icon: LucideIcons.filePen, color: c(AppColors.yellow700, AppColors.yellow300));
    return (label: 'Pendiente', icon: LucideIcons.clock, color: c(AppColors.neutral600, AppColors.neutral300));
  }
  if (entrega.calificada) {
    return (label: 'Calificado', icon: LucideIcons.award, color: c(AppColors.green700, AppColors.green300));
  }
  if (entrega.estado == 'tarde') {
    return (label: 'Entregado tarde', icon: LucideIcons.clockAlert, color: c(AppColors.yellow700, AppColors.yellow300));
  }
  return (label: 'Entregado', icon: LucideIcons.circleCheck, color: c(AppColors.blue700, AppColors.blue300));
}

class EstadoEntregaBadge extends StatelessWidget {
  const EstadoEntregaBadge({super.key, required this.entrega, this.tarea});

  final Entrega? entrega;
  final Tarea? tarea;

  @override
  Widget build(BuildContext context) {
    final v = estadoEntregaVisual(context, entrega, tarea);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: v.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: 14, color: v.color),
          const SizedBox(width: 4),
          Text(v.label, style: TextStyle(color: v.color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
