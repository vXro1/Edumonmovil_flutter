import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cursos/domain/entities/curso.dart';
import '../../../cursos/presentation/providers/cursos_providers.dart';
import '../../domain/entities/tarea.dart';
import '../providers/tareas_providers.dart';

/// Retos — gestión global de tareas del docente, across todos sus cursos —
/// BLUEPRINT.md FASE 3.12 / FASE 3.7.3 (padre: solo lectura, mismo canónico).
/// (⚠️) fetchTareas sin cursoId asume que el backend scopea automáticamente
/// al usuario autenticado (docente → sus cursos, padre → cursos de sus
/// hijos), igual que /cursos/mis-cursos.
class RetosScreen extends ConsumerStatefulWidget {
  const RetosScreen({super.key});

  @override
  ConsumerState<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends ConsumerState<RetosScreen> {
  List<Tarea> _items = const [];
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
      final result = await ref.read(tareasRepositoryProvider).fetchTareas(page: 1, limit: 50);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los retos.';
      });
    }
  }

  Future<void> _crearReto() async {
    final cursosRepo = ref.read(cursosRepositoryProvider);
    List<Curso> cursos;
    try {
      cursos = (await cursosRepo.fetchMisCursos(page: 1, limit: 50)).items;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudieron cargar tus cursos.')));
      return;
    }
    if (!mounted) return;
    if (cursos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todavía no tenés cursos creados.')));
      return;
    }

    final cursoId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Elegí un curso', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final curso in cursos)
              ListTile(
                leading: const Icon(LucideIcons.bookOpen, color: AppColors.accent),
                title: Text(curso.nombre),
                onTap: () => Navigator.of(context).pop(curso.id),
              ),
          ],
        ),
      ),
    );

    if (cursoId == null || !mounted) return;
    final created = await context.push<bool>('/cursos/$cursoId/tareas/nueva');
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(authControllerProvider).user?.rol;
    // Retos son contenido pedagógico: solo Docente (y superAdmin) gestiona;
    // Administrador solo visualiza.
    final canManage = rol == UserRole.docente || rol == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Retos')),
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: _crearReto, child: const Icon(LucideIcons.plus))
          : null,
      body: _loading
          ? const LoadingScreenWidget()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: AppColors.mutedText(context))),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(child: Text('Todavía no tenés retos creados.', style: TextStyle(color: AppColors.mutedText(context))))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final tarea = _items[index];
                          return EdumonCard(
                            onTap: () async {
                              final changed = await context.push<bool>('/tareas/${tarea.id}');
                              if (changed == true) _load();
                            },
                            child: Row(
                              children: [
                                Icon(
                                  tarea.vencida ? LucideIcons.clockAlert : LucideIcons.target,
                                  color: tarea.vencida ? AppColors.error : AppColors.sectionTareas,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tarea.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (tarea.cursoNombre != null)
                                        Text(tarea.cursoNombre!, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tarea.vencida
                                        ? AppColors.errorSurface(context.isDarkMode)
                                        : (tarea.cerrada
                                              ? (context.isDarkMode ? AppColors.surface2Dark : AppColors.neutral150)
                                              : AppColors.successSurface(context.isDarkMode)),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    tarea.vencida ? 'Vencida' : (tarea.cerrada ? 'Cerrada' : 'Activa'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: tarea.vencida ? AppColors.error : (tarea.cerrada ? AppColors.mutedText(context) : AppColors.success),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
