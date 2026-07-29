import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/mensaje_buzon.dart';
import '../providers/buzon_providers.dart';

enum _Filtro { todos, sinLeer, leidos }

/// Buzón (mensajería pública) — BLUEPRINT.md FASE 3.9. Ruta /buzon
/// (superadmin/admin). El formulario público de contacto es de la landing
/// web, no de esta app — acá solo se leen y marcan como leídos.
class BuzonScreen extends ConsumerStatefulWidget {
  const BuzonScreen({super.key});

  @override
  ConsumerState<BuzonScreen> createState() => _BuzonScreenState();
}

class _BuzonScreenState extends ConsumerState<BuzonScreen> {
  List<MensajeBuzon> _items = const [];
  bool _loading = true;
  String? _error;
  _Filtro _filtro = _Filtro.todos;

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
      final items = await ref.read(buzonRepositoryProvider).fetchMensajes();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los mensajes.';
      });
    }
  }

  Future<void> _abrirDetalle(MensajeBuzon mensaje) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
            Text(mensaje.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(mensaje.correo, style: TextStyle(color: AppColors.mutedText(context), fontSize: 13)),
            if (mensaje.telefono != null)
              Text(mensaje.telefono!, style: TextStyle(color: AppColors.mutedText(context), fontSize: 13)),
            if (mensaje.institucion != null)
              Text(mensaje.institucion!, style: TextStyle(color: AppColors.mutedText(context), fontSize: 13)),
            const SizedBox(height: AppSpacing.md),
            Text(mensaje.mensaje),
            const SizedBox(height: AppSpacing.md),
            Text(_formatFecha(mensaje.createdAt), style: TextStyle(color: AppColors.subtleText(context), fontSize: 12)),
          ],
        ),
      ),
    );

    if (!mensaje.leido) {
      try {
        await ref.read(buzonRepositoryProvider).marcarLeido(mensaje.id);
        _load();
      } catch (_) {
        // Best-effort — no interrumpe la lectura del mensaje si falla.
      }
    }
  }

  List<MensajeBuzon> get _filtrados {
    switch (_filtro) {
      case _Filtro.sinLeer:
        return _items.where((m) => !m.leido).toList();
      case _Filtro.leidos:
        return _items.where((m) => m.leido).toList();
      case _Filtro.todos:
        return _items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinLeer = _items.where((m) => !m.leido).length;
    final leidos = _items.where((m) => m.leido).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Buzón')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<_Filtro>(
              segments: [
                ButtonSegment(
                  value: _Filtro.todos,
                  label: Text('Todos (${_items.length})', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                ButtonSegment(
                  value: _Filtro.sinLeer,
                  label: Text('Sin leer ($sinLeer)', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                ButtonSegment(
                  value: _Filtro.leidos,
                  label: Text('Leídos ($leidos)', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
              selected: {_filtro},
              onSelectionChanged: (value) => setState(() => _filtro = value.first),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
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

    final items = _filtrados;
    if (items.isEmpty) {
      return Center(child: Text('No hay mensajes acá.', style: TextStyle(color: AppColors.mutedText(context))));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final m = items[index];
          return Opacity(
            opacity: m.leido ? 0.7 : 1,
            child: EdumonCard(
              onTap: () => _abrirDetalle(m),
              child: Row(
                children: [
                  Icon(m.leido ? LucideIcons.mailOpen : LucideIcons.mail, color: m.leido ? AppColors.mutedText(context) : AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nombre,
                          style: TextStyle(fontWeight: m.leido ? FontWeight.w500 : FontWeight.w700),
                        ),
                        Text(
                          m.mensaje,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(_formatFecha(m.createdAt), style: TextStyle(color: AppColors.subtleText(context), fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
