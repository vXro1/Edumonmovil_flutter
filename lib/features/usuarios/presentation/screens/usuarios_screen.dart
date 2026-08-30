import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../notificaciones/presentation/providers/notificacion_providers.dart';
import '../providers/usuarios_providers.dart';

const _pageSize = 15;

Color _roleColor(UserRole rol) {
  return switch (rol) {
    UserRole.superAdmin => AppColors.error,
    UserRole.administrador => AppColors.warning,
    UserRole.docente => AppColors.accent,
    UserRole.padreTutor => AppColors.success,
    UserRole.estudiante => AppColors.secondary,
  };
}

/// Usuarios — BLUEPRINT.md FASE 3.3.4.
/// (⚠️) getUsers real no soporta búsqueda por texto server-side (solo
/// rol/estado) — el campo de búsqueda filtra en cliente sobre lo cargado,
/// consistente con la recomendación de BLUEPRINT.md FASE 13.1.
class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  final _items = <User>[];
  final _searchController = TextEditingController();
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

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
      final result = await ref.read(usuariosRepositoryProvider).fetchUsuarios(page: page, limit: _pageSize);
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
        _error = e is AppException ? e.message : 'No se pudieron cargar los usuarios.';
      });
    }
  }

  Future<void> _toggleEstado(User user) async {
    final suspender = user.estado == 'activo';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suspender ? 'Suspender usuario' : 'Activar usuario'),
        content: Text(
          suspender
              ? '¿Suspender a ${user.nombreCompleto}? No va a poder iniciar sesión hasta que lo reactives.'
              : '¿Reactivar a ${user.nombreCompleto}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(suspender ? 'Suspender' : 'Activar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(usuariosRepositoryProvider);
      if (suspender) {
        await repo.suspenderUsuario(user.id);
      } else {
        await repo.activarUsuario(user.id);
      }
      _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo completar la acción.')));
    }
  }

  // createNotificacion real (POST /notificaciones, admin/superadmin) — envía
  // una notificación puntual a un usuario, distinta de las que genera el
  // sistema automáticamente (nueva tarea, calificación, etc.).
  Future<void> _notificar(User user) async {
    final tituloController = TextEditingController();
    final mensajeController = TextEditingController();
    String? error;
    bool sending = false;

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Notificar a ${user.nombreCompleto}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                ],
                EdumonTextField(controller: tituloController, label: 'Título'),
                EdumonTextField(controller: mensajeController, label: 'Mensaje', maxLines: 4, minLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            EdumonButton(
              label: 'Enviar',
              loading: sending,
              onPressed: sending
                  ? null
                  : () async {
                      final titulo = tituloController.text.trim();
                      final mensaje = mensajeController.text.trim();
                      if (titulo.isEmpty || mensaje.isEmpty) {
                        setDialogState(() => error = 'Completá título y mensaje.');
                        return;
                      }
                      setDialogState(() => sending = true);
                      try {
                        await ref
                            .read(notificacionRepositoryProvider)
                            .createNotificacion(usuarioId: user.id, titulo: titulo, mensaje: mensaje);
                        if (context.mounted) Navigator.of(context).pop(true);
                      } catch (e) {
                        setDialogState(() {
                          sending = false;
                          error = e is AppException ? e.message : 'No se pudo enviar la notificación.';
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificación enviada.')));
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
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/usuarios/nuevo');
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
          Expanded(child: _buildBody(currentUserId)),
        ],
      ),
    );
  }

  Widget _buildBody(String? currentUserId) {
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
      return Center(child: Text('No hay usuarios que coincidan.', style: TextStyle(color: AppColors.mutedText(context))));
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

          final user = filtered[index];
          final activo = user.estado == 'activo';
          return EdumonCard(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              children: [
                // Toda esta zona (avatar + datos + flecha) es la única que
                // navega a ver/editar — separada del botón de
                // suspender/activar para que un toque impreciso sobre ese
                // botón no dispare la navegación por error.
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () async {
                      // Editar la propia fila por acá cae siempre en 403: el
                      // backend no permite auto-modificarse vía el endpoint
                      // administrativo genérico PUT /users/:id (solo expone
                      // self-service para foto de perfil/token FCM). En vez
                      // de dejar que el usuario choque con ese error,
                      // redirigimos a su propio perfil.
                      if (user.id == currentUserId) {
                        context.push('/perfil');
                        return;
                      }
                      final updated = await context.push<bool>('/usuarios/${user.id}');
                      if (updated == true) _loadPage(1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          EdumonAvatar(
                            radius: 20,
                            imageUrl: user.avatarUrl,
                            backgroundColor: _roleColor(user.rol).withValues(alpha: 0.15),
                            fallbackText: user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                            fallbackColor: _roleColor(user.rol),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.nombreCompleto,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'CC ${user.cedula}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _roleColor(user.rol).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        user.rol.label,
                                        style: TextStyle(
                                          color: _roleColor(user.rol),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: activo
                                            ? AppColors.successSurface(context.isDarkMode)
                                            : AppColors.errorSurface(context.isDarkMode),
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        activo ? 'Activo' : 'Suspendido',
                                        style: TextStyle(
                                          color: activo ? AppColors.success : AppColors.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(LucideIcons.chevronRight, color: AppColors.subtleText(context), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                if (user.id != currentUserId)
                  IconButton(
                    tooltip: 'Enviar notificación',
                    icon: const Icon(LucideIcons.bell),
                    onPressed: () => _notificar(user),
                  ),
                // Botón real de suspender/activar — 48x48 mínimo, separado e
                // independiente del área de "ver/editar" de arriba.
                IconButton(
                  tooltip: activo ? 'Suspender usuario' : 'Activar usuario',
                  icon: Icon(activo ? LucideIcons.userX : LucideIcons.userCheck),
                  color: activo ? AppColors.error : AppColors.success,
                  onPressed: () => _toggleEstado(user),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
