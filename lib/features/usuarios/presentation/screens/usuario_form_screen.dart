import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/dialogs/edumon_dialog.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/design_system/loading/loading_screen.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/security/role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/usuarios_providers.dart';

/// Crear/editar usuario — BLUEPRINT.md FASE 3.3.4.
/// [userId] null = modo crear; con valor = modo editar/detalle.
class UsuarioFormScreen extends ConsumerStatefulWidget {
  const UsuarioFormScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends ConsumerState<UsuarioFormScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  UserRole _rol = UserRole.padreTutor;
  String? _institucionId;

  bool _loadingUser = false;
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isEditing => widget.userId != null;
  bool get _needsInstitucion => _rol == UserRole.docente || _rol == UserRole.administrador;

  @override
  void initState() {
    super.initState();
    _cedulaController.addListener(() => setState(() {}));
    if (_isEditing) _loadUser();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);
    try {
      final user = await ref.read(usuariosRepositoryProvider).fetchUsuarioById(widget.userId!);
      if (!mounted) return;
      _nombreController.text = user.nombre;
      _apellidoController.text = user.apellido;
      _cedulaController.text = user.cedula;
      // El campo solo edita los 10 dígitos locales (como en login/wizard) —
      // se le quita el "+57" si el valor que mandó el backend ya lo trae,
      // para que el formatter digitsOnly/10 no lo trunque a mitad.
      final digitosTelefono = user.telefono.replaceAll(RegExp(r'\D'), '');
      _telefonoController.text = digitosTelefono.length > 10
          ? digitosTelefono.substring(digitosTelefono.length - 10)
          : digitosTelefono;
      _correoController.text = user.correo ?? '';
      setState(() {
        _rol = user.rol;
        _institucionId = user.institucionId;
        _loadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo cargar el usuario.');
    }
  }

  Future<void> _submit() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final cedula = _cedulaController.text.trim();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim();

    final errors = <String, String>{};
    if (nombre.isEmpty) {
      errors['nombre'] = 'Ingresá el nombre.';
    } else if (!AppConstants.nombreRegex.hasMatch(nombre)) {
      errors['nombre'] = 'El nombre solo puede contener letras y espacios.';
    }
    if (apellido.isEmpty) {
      errors['apellido'] = 'Ingresá el apellido.';
    } else if (!AppConstants.nombreRegex.hasMatch(apellido)) {
      errors['apellido'] = 'El apellido solo puede contener letras y espacios.';
    }
    if (!AppConstants.cedulaRegex.hasMatch(cedula)) errors['cedula'] = 'La cédula debe tener entre 6 y 10 dígitos.';
    if (!AppConstants.phoneRegex.hasMatch(telefono)) errors['telefono'] = 'El teléfono debe tener 10 dígitos.';
    // userValidator.js real: createUserValidator exige correo (.notEmpty()),
    // updateUserValidator lo deja opcional (.optional()) — la regla difiere
    // según si se está creando o editando.
    if (!_isEditing && correo.isEmpty) {
      errors['correo'] = 'El correo es requerido.';
    } else if (correo.isNotEmpty && !AppConstants.emailRegex.hasMatch(correo)) {
      errors['correo'] = 'El formato del correo no es válido.';
    }
    if (_needsInstitucion && _institucionId == null) errors['institucionId'] = 'Seleccioná una institución.';

    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(usuariosRepositoryProvider);
      // userValidator.js real (createUserValidator/updateUserValidator) exige
      // el teléfono en formato +57XXXXXXXXXX — igual que loginValidator. El
      // campo acá solo captura los 10 dígitos locales, así que hay que anteponer
      // "+57" antes de mandarlo, igual que ya hace AuthRemoteDataSource.login().
      // Sin esto, el usuario quedaba guardado con el teléfono en un formato
      // distinto al que login normaliza para buscarlo → "credenciales inválidas"
      // aunque la contraseña fuera la correcta.
      final telefonoConPrefijo = '+57$telefono';
      if (_isEditing) {
        // userValidator.js real (updateUser): el controlador borra
        // rol/estado/institucionId de updateData ANTES de guardar — no se
        // mandan más porque el backend los ignora en silencio (no es un
        // "no autorizado", el request "funciona" pero el cambio nunca se
        // aplica). Ver el bloque de solo-lectura en build() más abajo.
        await repo.updateUsuario(
          id: widget.userId!,
          nombre: nombre,
          apellido: apellido,
          cedula: cedula,
          telefono: telefonoConPrefijo,
          correo: correo.isEmpty ? null : correo,
        );
      } else {
        await repo.createUsuario(
          nombre: nombre,
          apellido: apellido,
          cedula: cedula,
          telefono: telefonoConPrefijo,
          rol: _rol,
          // BUG REAL corregido: createUserValidator.contraseña exige al
          // menos una minúscula, una mayúscula y un dígito — la cédula sola
          // (todo dígitos) nunca cumplía eso y el alta fallaba siempre con
          // 400. "Cc" + cédula es la contraseña que ya se le mostraba al
          // admin en pantalla, pero nunca era la que en verdad se mandaba.
          contrasena: 'Cc$cedula',
          correo: correo.isEmpty ? null : correo,
          institucionId: _needsInstitucion ? _institucionId : null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e is AppException && e.fieldErrors != null) _fieldErrors = e.fieldErrors!;
      });
      EdumonDialog.show(context, message: e is AppException ? e.message : 'No se pudo guardar el usuario.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(authControllerProvider).user?.rol;
    final isSuperAdmin = currentRole == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar usuario' : 'Nuevo usuario')),
      body: _loadingUser
          ? const LoadingScreenWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EdumonTextField(controller: _nombreController, label: 'Nombre', errorText: _fieldErrors['nombre']),
                  EdumonTextField(controller: _apellidoController, label: 'Apellido', errorText: _fieldErrors['apellido']),
                  EdumonTextField(
                    controller: _cedulaController,
                    label: 'Cédula',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    errorText: _fieldErrors['cedula'],
                  ),
                  EdumonTextField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    prefixText: '+57 ',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    errorText: _fieldErrors['telefono'],
                  ),
                  EdumonTextField(
                    controller: _correoController,
                    label: _isEditing ? 'Correo (opcional)' : 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _fieldErrors['correo'],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Rol', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  // userController.js real (updateUser) borra "rol" de
                  // updateData antes de guardar — PUT /users/:id no puede
                  // reasignar el rol de un usuario existente. Mostrarlo
                  // editable acá era engañoso (mismo patrón ya corregido
                  // para el docente titular en curso_form_screen.dart).
                  _isEditing
                      ? Text(_rol.label, style: TextStyle(color: AppColors.mutedText(context)))
                      : DropdownButtonFormField<UserRole>(
                          initialValue: _rol,
                          items: UserRole.values
                              .where((r) => isSuperAdmin || r != UserRole.superAdmin)
                              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                              .toList(),
                          onChanged: (value) => setState(() => _rol = value ?? _rol),
                        ),
                  if (_needsInstitucion) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Institución', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (_isEditing)
                      Consumer(
                        builder: (context, ref, _) {
                          // institucionId tampoco se puede reasignar al
                          // editar (mismo motivo que "rol" arriba) — se
                          // resuelve el nombre solo para mostrarlo, nunca
                          // para mandarlo de vuelta.
                          final institucionesAsync = ref.watch(institucionesProvider);
                          return institucionesAsync.when(
                            data: (instituciones) {
                              final nombre = instituciones
                                  .where((i) => i.id == _institucionId)
                                  .map((i) => i.nombre)
                                  .firstOrNull;
                              return Text(nombre ?? 'Sin institución', style: TextStyle(color: AppColors.mutedText(context)));
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => Text('—', style: TextStyle(color: AppColors.mutedText(context))),
                          );
                        },
                      )
                    else if (isSuperAdmin)
                      Consumer(
                        builder: (context, ref, _) {
                          final institucionesAsync = ref.watch(institucionesProvider);
                          return institucionesAsync.when(
                            data: (instituciones) {
                              // DropdownButtonFormField exige que initialValue coincida con
                              // algún item o sea null — si la institución del usuario no está
                              // en la lista cargada (paginación, institución archivada, etc.)
                              // pasarla igual crashea la pantalla entera. Se valida antes.
                              final initial = instituciones.any((i) => i.id == _institucionId) ? _institucionId : null;
                              return DropdownButtonFormField<String>(
                                initialValue: initial,
                                isExpanded: true,
                                items: instituciones
                                    .map(
                                      (i) => DropdownMenuItem(
                                        value: i.id,
                                        child: Text(i.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(() => _institucionId = value),
                                hint: const Text('Seleccioná una institución'),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => Row(
                              children: [
                                const Expanded(child: Text('No se pudieron cargar las instituciones.')),
                                TextButton(
                                  onPressed: () => ref.invalidate(institucionesProvider),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Builder(
                        builder: (context) {
                          final adminInstitucionId = ref.read(authControllerProvider).user?.institucionId;
                          if (_institucionId == null && adminInstitucionId != null) {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => setState(() => _institucionId = adminInstitucionId),
                            );
                          }
                          return Text(
                            'Se asigna automáticamente a tu institución.',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                          );
                        },
                      ),
                    if (_fieldErrors['institucionId'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _fieldErrors['institucionId']!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                  ],
                  if (!_isEditing && AppConstants.cedulaRegex.hasMatch(_cedulaController.text.trim())) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'La contraseña inicial será: Cc${_cedulaController.text.trim()}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  EdumonButton(
                    label: _isEditing ? 'Guardar cambios' : 'Crear usuario',
                    onPressed: _saving ? null : _submit,
                    loading: _saving,
                    fullWidth: true,
                    size: EdumonButtonSize.lg,
                  ),
                ],
              ),
            ),
    );
  }
}
