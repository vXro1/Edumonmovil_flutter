/// Rol único y canónico — BLUEPRINT.md FASE 11.5.
/// A diferencia de la web (2 taxonomías divergentes puenteadas por
/// heurística de substring), acá hay un solo enum con mapeo exhaustivo.
enum UserRole {
  superAdmin,
  administrador,
  docente,
  padreTutor,
  estudiante;

  /// Mapeo explícito desde el string que devuelve el backend.
  /// Sin `.contains()`/substring matching — cualquier valor no reconocido
  /// lanza, para detectar cambios de contrato temprano en vez de silenciarlos.
  static UserRole fromApiString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
      case 'super-admin':
        return UserRole.superAdmin;
      case 'administrador':
      case 'admin':
        return UserRole.administrador;
      case 'docente':
        return UserRole.docente;
      case 'padre':
      case 'padre/tutor':
      case 'padre_tutor':
      case 'tutor':
        return UserRole.padreTutor;
      case 'estudiante':
        return UserRole.estudiante;
      default:
        throw ArgumentError('Rol desconocido recibido del backend: "$raw"');
    }
  }

  /// Ruta lógica de inicio para este rol — replica ROLE_HOME de la web.
  String get homeRoute {
    switch (this) {
      case UserRole.superAdmin:
      case UserRole.administrador:
        return '/admin';
      case UserRole.docente:
        return '/docente';
      case UserRole.padreTutor:
        return '/padre';
      case UserRole.estudiante:
        // Sin flujo de login propio hoy (BLUEPRINT.md FASE 1.1 / 4.2).
        return '/padre';
    }
  }

  /// Valor canónico que espera el backend al crear/editar un usuario
  /// (userController.js real: 'superadmin'|'docente'|'administrador'|'padre').
  String get toApiString {
    switch (this) {
      case UserRole.superAdmin:
        return 'superadmin';
      case UserRole.administrador:
        return 'administrador';
      case UserRole.docente:
        return 'docente';
      case UserRole.padreTutor:
        return 'padre';
      case UserRole.estudiante:
        return 'estudiante';
    }
  }

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super administrador';
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.docente:
        return 'Docente';
      case UserRole.padreTutor:
        return 'Padre/Tutor';
      case UserRole.estudiante:
        return 'Estudiante';
    }
  }
}
