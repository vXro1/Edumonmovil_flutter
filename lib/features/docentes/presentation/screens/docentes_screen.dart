import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../usuarios/presentation/providers/usuarios_providers.dart';
import '../providers/docentes_providers.dart';

const _pageSize = 15;

/// Docentes (admin) — BLUEPRINT.md FASE 3.3.3.
/// El listado reutiliza GET /users?rol=docente (mismo endpoint que Usuarios,
/// filtrado por rol) — no hay un GET dedicado de docentes en el blueprint,
/// solo POST para crear/importar.
class DocentesScreen extends ConsumerStatefulWidget {
  const DocentesScreen({super.key});

  @override
  ConsumerState<DocentesScreen> createState() => _DocentesScreenState();
}

class _DocentesScreenState extends ConsumerState<DocentesScreen> {
  final _items = <User>[];
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  bool _importing = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadPage(1);
    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _search = _searchController.text.trim().toLowerCase());
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      if (page == 1) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });
    try {
      final result = await ref
          .read(usuariosRepositoryProvider)
          .fetchUsuarios(page: page, limit: _pageSize, rol: UserRole.docente);
      if (!mounted) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(result.items);
        _page = page;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los docentes.';
      });
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;

    setState(() => _importing = true);
    try {
      final summary = await ref
          .read(docentesRepositoryProvider)
          .importCsv(bytes: file.bytes!, filename: file.name);
      if (!mounted) return;
      setState(() => _importing = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resultado de la importación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total procesados: ${summary.total}', style: TextStyle(color: AppColors.mutedText(context))),
                const SizedBox(height: 4),
                _ImportResultRow(
                  icon: LucideIcons.check,
                  color: AppColors.success,
                  text: '${summary.exitosos} creados/asignados',
                ),
                _ImportResultRow(
                  icon: LucideIcons.triangleAlert,
                  color: AppColors.warning,
                  text: '${summary.duplicados} duplicados',
                ),
                _ImportResultRow(
                  icon: LucideIcons.x,
                  color: AppColors.error,
                  text: '${summary.errores} con error',
                ),
                if (summary.detallesErrores.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Errores:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ...summary.detallesErrores.take(10).map(
                    (e) => Text('• ${e.nombre.isNotEmpty ? e.nombre : e.cedula}: ${e.motivo}', style: const TextStyle(fontSize: 12)),
                  ),
                ],
                if (summary.detallesDuplicados.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Duplicados:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ...summary.detallesDuplicados.take(10).map(
                    (e) => Text('• ${e.nombre.isNotEmpty ? e.nombre : e.cedula}: ${e.motivo}', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
        ),
      );
      _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo importar el CSV.')));
    }
  }

  List<User> get _filteredItems {
    if (_search.isEmpty) return _items;
    return _items.where((u) {
      return u.nombreCompleto.toLowerCase().contains(_search) ||
          u.cedula.contains(_search) ||
          (u.correo?.toLowerCase().contains(_search) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docentes'),
        actions: [
          IconButton(
            icon: _importing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.fileUp),
            tooltip: 'Importar CSV',
            onPressed: _importing ? null : _importCsv,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/docentes/nuevo');
          if (created == true) _loadPage(1);
        },
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre, cédula o correo…',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingScreenWidget();

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifiOff, size: 40, color: AppColors.subtleText(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: () => _loadPage(1), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredItems;
    if (filtered.isEmpty) {
      return Center(child: Text('No hay docentes que coincidan.', style: TextStyle(color: AppColors.mutedText(context))));
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(1),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: filtered.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            if (_search.isNotEmpty || !_hasMore) return const SizedBox(height: AppSpacing.lg);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: () => _loadPage(_page + 1), child: const Text('Cargar más')),
              ),
            );
          }

          final docente = filtered[index];
          return EdumonCard(
            child: Row(
              children: [
                EdumonAvatar(
                  radius: 20,
                  imageUrl: docente.avatarUrl,
                  backgroundColor: AppColors.accentLight,
                  fallbackText: docente.nombre.isNotEmpty ? docente.nombre[0].toUpperCase() : '?',
                  fallbackColor: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(docente.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('CC ${docente.cedula}', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                      if (docente.correo != null)
                        Text(docente.correo!, style: TextStyle(color: AppColors.subtleText(context), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: docente.estado == 'activo'
                        ? AppColors.successSurface(context.isDarkMode)
                        : AppColors.errorSurface(context.isDarkMode),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    docente.estado,
                    style: TextStyle(
                      color: docente.estado == 'activo' ? AppColors.success : AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fila ícono+texto para resultados de importación — sin emojis (regla de diseño).
class _ImportResultRow extends StatelessWidget {
  const _ImportResultRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
