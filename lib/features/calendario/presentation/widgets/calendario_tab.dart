import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/calendario_aggregator.dart';
import '../../domain/entities/calendario_entry.dart';

/// Tab Calendario (dentro de curso) — BLUEPRINT.md FASE 3.4.10.
/// Combina tareas + eventos del curso en un grid mensual, poblado desde
/// GET /calendario/:cursoId real (ver calendario_aggregator.dart).
class CalendarioTab extends ConsumerStatefulWidget {
  const CalendarioTab({super.key, required this.cursoId, required this.canManage});

  final String cursoId;
  final bool canManage;

  @override
  ConsumerState<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends ConsumerState<CalendarioTab> {
  List<CalendarioEntry> _entries = const [];
  bool _loading = true;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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
      final entries = await loadCalendarioEntries(ref, cursoId: widget.cursoId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudo cargar el calendario.';
      });
    }
  }

  List<CalendarioEntry> _entriesFor(DateTime day) {
    return _entries.where((e) => isSameDay(e.fecha, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>('/eventos/nuevo', extra: widget.cursoId);
                if (created == true) _load();
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
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

    final seleccionados = _entriesFor(_selectedDay);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TableCalendar<CalendarioEntry>(
            locale: 'es_CO',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _entriesFor,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(color: AppColors.sectionCalendario, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          const SizedBox(height: AppSpacing.md),
          if (seleccionados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('Sin retos ni eventos ese día.', style: TextStyle(color: AppColors.mutedText(context)))),
            )
          else
            ...seleccionados.map((e) => _EntryTile(entry: e)),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final CalendarioEntry entry;

  @override
  Widget build(BuildContext context) {
    final esTarea = entry.tipo == CalendarioEntryTipo.tarea;
    final color = esTarea ? AppColors.sectionTareas : AppColors.sectionCalendario;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: EdumonCard(
        child: Row(
          children: [
            Icon(esTarea ? LucideIcons.target : LucideIcons.calendarDays, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.titulo, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  Text(
                    esTarea ? (entry.vencida ? 'Reto vencido' : 'Reto') : (entry.categoria ?? 'Evento'),
                    style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
