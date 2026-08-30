import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/curso_thumbnail.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/curso.dart';
import '../providers/cursos_providers.dart';

const _pageSize = 15;

/// Lista de cursos — BLUEPRINT.md FASE 3.4.1 / FASE 3.7.2. Docente y padre
/// ven "mis cursos" (/cursos/mis-cursos, filtra por
/// `participantes.usuarioId`); superadmin/admin ven todos los de la
/// institución (/cursos) — mismo canónico para todos, sin replicar una
/// pantalla "Familia · Cursos" aparte.
/// BUG REAL corregido: cursoController.js real (getCursos) solo filtra por
/// institucionId/estado/docenteId — NO scopea por participación del usuario
/// pese a lo que decía este comentario antes. Un padre entrando a "Cursos"
/// usando /cursos veía TODOS los cursos de la institución (con docente y
/// participantes de cursos donde ni siquiera está inscrito), no solo los
/// suyos. /cursos/mis-cursos sí filtra por `participantes.usuarioId` para
/// cualquier rol (no es exclusivo de docente), así que padre debe usarlo igual.
/// (⚠️) getCursos real no lee ningún parámetro de texto — solo filtra por
/// estado/docenteId — así que la búsqueda es client-side sobre lo ya
/// cargado, igual que en Usuarios/Docentes.
class CursosScreen extends ConsumerStatefulWidget {
  const CursosScreen({super.key});

  @override
  ConsumerState<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends ConsumerState<CursosScreen> {
  final _items = <Curso>[];
  final _searchController = TextEditingController();
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

  bool get _isDocente => ref.read(authControllerProvider).user?.rol == UserRole.docente;

  // Docente y padre solo deben ver los cursos donde participan
  // (/cursos/mis-cursos) — admin/superAdmin ven todos los de la institución.
  bool get _scopeToMisCursos {
    final rol = ref.read(authControllerProvider).user?.rol;
    return rol == UserRole.docente || rol == UserRole.padreTutor;
  }

  bool get _canManage {
    final rol = ref.read(authControllerProvider).user?.rol;
    return rol == UserRole.docente || rol == UserRole.administrador || rol == UserRole.superAdmin;
  }

  @override
  void initState() {
    super.initState();
    _loadPage(1);
    _searchController.addListener(() => setState(() => _search = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
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
      final repo = ref.read(cursosRepositoryProvider);
      final result = _scopeToMisCursos
          ? await repo.fetchMisCursos(page: page, limit: _pageSize)
          : await repo.fetchCursos(page: page, limit: _pageSize);
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
        _error = e is AppException ? e.message : 'No se pudieron cargar los cursos.';
      });
    }
  }

  Future<void> _restore(Curso curso) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar curso'),
        content: Text('¿Restaurar "${curso.nombre}"? Vuelve a estar activo para sus participantes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(cursosRepositoryProvider).restoreCurso(curso.id);
      _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo restaurar el curso.')));
    }
  }

  Future<void> _archive(Curso curso) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar curso'),
        content: Text('¿Archivar "${curso.nombre}"? Deja de estar activo para sus participantes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Archivar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(cursosRepositoryProvider).archiveCurso(curso.id);
      _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo archivar el curso.')));
    }
  }

  /// cursoController.js real valida `color` como #RGB o #RRGGBB — acá se
  /// parsea de forma defensiva por si algún curso viejo trae un valor
  /// inválido (nunca debería, pero no vale la pena romper la lista por eso).
  Color? _parseCursoColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.replaceFirst('#', '');
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length != 6) return null;
    final intValue = int.tryParse(value, radix: 16);
    return intValue == null ? null : Color(0xFF000000 | intValue);
  }

  List<Curso> get _filteredItems {
    if (_search.isEmpty) return _items;
    return _items.where((c) => c.nombre.toLowerCase().contains(_search)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cursos')),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>('/cursos/nuevo');
                if (created == true) _loadPage(1);
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Column(
        children: [
          if (!_scopeToMisCursos)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Buscar curso…', prefixIcon: Icon(LucideIcons.search)),
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
      return Center(
        child: Text(
          _search.isNotEmpty
              ? 'No hay cursos que coincidan.'
              : (_isDocente
                    ? 'Todavía no tenés cursos. Creá el primero.'
                    : (_scopeToMisCursos ? 'Todavía no estás en ningún curso.' : 'No hay cursos registrados.')),
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
      );
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

          final curso = filtered[index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cursoColor = _parseCursoColor(curso.color);
          return EdumonCard(
            onTap: () => context.push('/cursos/${curso.id}'),
            child: Row(
              children: [
                CursoThumbnail(
                  imageUrl: curso.imagenUrl,
                  radius: 24,
                  icon: LucideIcons.bookOpen,
                  iconColor: cursoColor ?? AppColors.accent,
                  backgroundColor: cursoColor?.withValues(alpha: 0.16) ?? AppColors.accentLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(curso.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (curso.docente != null)
                        Text(curso.docente!.nombreCompleto, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                      Text('${curso.totalParticipantes} participantes', style: TextStyle(color: AppColors.subtleText(context), fontSize: 12)),
                    ],
                  ),
                ),
                if (curso.archivado) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface2Dark : AppColors.neutral150,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'Archivado',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (_canManage)
                    IconButton(
                      icon: Icon(LucideIcons.archiveRestore, size: 18, color: AppColors.subtleText(context)),
                      tooltip: 'Restaurar curso',
                      onPressed: () => _restore(curso),
                    ),
                ] else if (_canManage)
                  IconButton(
                    icon: Icon(LucideIcons.archive, size: 18, color: AppColors.subtleText(context)),
                    tooltip: 'Archivar curso',
                    onPressed: () => _archive(curso),
                  ),
                Icon(LucideIcons.chevronRight, color: AppColors.subtleText(context), size: 18),
              ],
            ),
          );
        },
      ),
    );
  }
}
