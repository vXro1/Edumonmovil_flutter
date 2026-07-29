import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../calendario/presentation/widgets/calendario_tab.dart';
import '../../../foros/presentation/widgets/foros_tab.dart';
import '../providers/cursos_providers.dart';
import '../widgets/modulos_tab.dart';
import '../widgets/participantes_tab.dart';
import '../widgets/tareas_tab.dart';

/// Hub de curso — BLUEPRINT.md FASE 3.4.2. 5 tabs por permiso: Módulos,
/// Tareas, Calendario, Foros (siempre), Participantes (oculto padre).
class CursoHubScreen extends ConsumerStatefulWidget {
  const CursoHubScreen({super.key, required this.cursoId});

  final String cursoId;

  @override
  ConsumerState<CursoHubScreen> createState() => _CursoHubScreenState();
}

class _CursoHubScreenState extends ConsumerState<CursoHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final rol = ref.read(authControllerProvider).user?.rol;
    final showParticipantes = rol != UserRole.padreTutor;
    _tabController = TabController(length: showParticipantes ? 5 : 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cursoAsync = ref.watch(cursoDetailProvider(widget.cursoId));
    final rol = ref.watch(authControllerProvider).user?.rol;
    final canManage = rol == UserRole.docente || rol == UserRole.administrador || rol == UserRole.superAdmin;
    // Módulos/Retos/Foros son contenido pedagógico: solo Docente (y
    // superAdmin, por privilegio de plataforma) puede crear/editar/eliminar.
    // Administrador solo puede visualizar — ver BLUEPRINT.md permisos por rol.
    final canManageContent = rol == UserRole.docente || rol == UserRole.superAdmin;
    final showParticipantes = rol != UserRole.padreTutor;

    return Scaffold(
      appBar: AppBar(
        title: cursoAsync.when(
          data: (curso) => Text(curso.nombre),
          loading: () => const Text('Curso'),
          error: (_, _) => const Text('Curso'),
        ),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'Editar curso',
              onPressed: () async {
                final updated = await context.push<bool>('/cursos/${widget.cursoId}/editar');
                if (updated == true) ref.invalidate(cursoDetailProvider(widget.cursoId));
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'Módulos'),
            const Tab(text: 'Retos'),
            const Tab(text: 'Calendario'),
            const Tab(text: 'Foros'),
            if (showParticipantes) const Tab(text: 'Participantes'),
          ],
        ),
      ),
      body: cursoAsync.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            ModulosTab(cursoId: widget.cursoId, canManage: canManageContent),
            TareasTab(cursoId: widget.cursoId, canManage: canManageContent),
            CalendarioTab(cursoId: widget.cursoId, canManage: canManage),
            ForosTab(cursoId: widget.cursoId, canManage: canManageContent),
            if (showParticipantes) ParticipantesTab(cursoId: widget.cursoId, canManage: canManage),
          ],
        ),
        loading: () => const LoadingScreenWidget(),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudo cargar el curso.', style: TextStyle(color: AppColors.mutedText(context))),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(cursoDetailProvider(widget.cursoId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
