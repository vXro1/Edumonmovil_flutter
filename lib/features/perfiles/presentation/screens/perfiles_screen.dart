import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/avatars/edumon_avatar.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/cards/edumon_card.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/perfil.dart';
import '../providers/perfiles_providers.dart';

const _maxSecundarios = 5;

/// Perfiles familiares — BLUEPRINT.md FASE 3.7.1.
/// Máx 5 perfiles secundarios + titular. Seleccionar perfil activo reemplaza
/// la sesión sin logout (ver perfiles_repository.dart).
class PerfilesScreen extends ConsumerStatefulWidget {
  const PerfilesScreen({super.key});

  @override
  ConsumerState<PerfilesScreen> createState() => _PerfilesScreenState();
}

class _PerfilesScreenState extends ConsumerState<PerfilesScreen> {
  List<Perfil> _items = const [];
  bool _loading = true;
  bool _switching = false;
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
      final activePerfilId = ref.read(authControllerProvider).perfilActivo?.id;
      final items = await ref.read(perfilesRepositoryProvider).fetchPerfiles(activePerfilId: activePerfilId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AppException ? e.message : 'No se pudieron cargar los perfiles.';
      });
    }
  }

  int get _secundariosCount => _items.where((p) => !p.esTitular).length;

  Future<void> _seleccionar(Perfil perfil) async {
    if (perfil.esActivo) return;
    setState(() => _switching = true);
    try {
      await ref.read(perfilesRepositoryProvider).seleccionarPerfil(perfil.id);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      setState(() => _switching = false);
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _switching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo cambiar de perfil.')));
    }
  }

  Future<void> _openForm({Perfil? existing}) async {
    if (existing == null && _secundariosCount >= _maxSecundarios) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ya llegaste al máximo de 5 perfiles secundarios.')));
      return;
    }

    final nombreController = TextEditingController(text: existing?.nombre);
    String? selectedAvatar = existing?.avatarUrl;
    List<String> avatars = const [];
    bool avatarsLoading = true;
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (avatarsLoading) {
            ref.read(profileRepositoryProvider).fetchDefaultAvatars().then((result) {
              if (context.mounted) {
                setSheetState(() {
                  avatars = result;
                  avatarsLoading = false;
                });
              }
            }).catchError((_) {
              if (context.mounted) setSheetState(() => avatarsLoading = false);
            });
          }

          return Padding(
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
                Text(existing == null ? 'Nuevo perfil' : 'Editar perfil', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: EdumonAvatar(
                    radius: 40,
                    imageUrl: selectedAvatar,
                    showBorder: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (avatarsLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.sm), child: CircularProgressIndicator()))
                else
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: avatars.asMap().entries.map((entry) {
                      final url = entry.value;
                      final selected = selectedAvatar == url;
                      return EdumonAvatar(
                        radius: 22,
                        imageUrl: url,
                        backgroundColor: AppColors.surface2,
                        showBorder: true,
                        selected: selected,
                        semanticLabel: 'Avatar ${entry.key + 1}',
                        onTap: () => setSheetState(() => selectedAvatar = url),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: AppSpacing.md),
                EdumonTextField(controller: nombreController, label: 'Nombre'),
                const SizedBox(height: AppSpacing.sm),
                EdumonButton(
                  label: 'Guardar',
                  fullWidth: true,
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final nombre = nombreController.text.trim();
                          if (nombre.isEmpty) {
                            EdumonDialog.show(context, message: 'Ingresá un nombre.');
                            return;
                          }
                          setSheetState(() => saving = true);
                          try {
                            final repo = ref.read(perfilesRepositoryProvider);
                            if (existing == null) {
                              await repo.createPerfil(nombre: nombre, avatarUrl: selectedAvatar);
                            } else {
                              await repo.updatePerfil(id: existing.id, nombre: nombre, avatarUrl: selectedAvatar);
                            }
                            if (context.mounted) Navigator.of(context).pop(true);
                          } catch (e) {
                            setSheetState(() => saving = false);
                            if (context.mounted) {
                              EdumonDialog.show(
                                context,
                                message: e is AppException ? e.message : 'No se pudo guardar el perfil.',
                              );
                            }
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _delete(Perfil perfil) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar perfil'),
        content: Text(
          perfil.esActivo
              ? '¿Eliminar "${perfil.nombre}"? Es tu perfil activo — al eliminarlo volvés al perfil titular.'
              : '¿Eliminar "${perfil.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(perfilesRepositoryProvider).deletePerfil(perfil.id);
      if (perfil.esActivo) await ref.read(authControllerProvider.notifier).refreshUser();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e is AppException ? e.message : 'No se pudo eliminar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfiles familiares')),
      floatingActionButton: _secundariosCount < _maxSecundarios
          ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(LucideIcons.plus))
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final perfil = _items[index];
          return EdumonCard(
            onTap: _switching ? null : () => _seleccionar(perfil),
            child: Row(
              children: [
                EdumonAvatar(
                  radius: 24,
                  imageUrl: perfil.avatarUrl,
                  fallbackText: perfil.nombre.isNotEmpty ? perfil.nombre[0].toUpperCase() : '?',
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(perfil.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        perfil.esTitular ? 'Titular' : 'Perfil secundario',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (perfil.esActivo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface(context.isDarkMode),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text('Activo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ),
                if (!perfil.esTitular) ...[
                  IconButton(
                    icon: Icon(LucideIcons.pencil, size: 18, color: AppColors.subtleText(context)),
                    tooltip: 'Editar perfil',
                    onPressed: () => _openForm(existing: perfil),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                    tooltip: 'Eliminar perfil',
                    onPressed: () => _delete(perfil),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
