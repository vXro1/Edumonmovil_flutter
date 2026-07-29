class AppConstants {
  const AppConstants._();

  static const String secureStorageTokenKey = 'edumon_auth_token';
  static const Duration inactivityTimeout = Duration(minutes: 30);
  static const Duration inactivityWarningBefore = Duration(minutes: 2);
  static const Duration sessionCheckInterval = Duration(minutes: 5);
  static const Duration jwtExpiryGrace = Duration(seconds: 30);

  static final RegExp phoneRegex = RegExp(r'^\d{10}$');
  // FASE 3.1.3: la recuperación acepta un formato más laxo (con + opcional,
  // 7-15 dígitos) que el login (10 dígitos fijos sin +57 visible).
  static final RegExp recoveryPhoneRegex = RegExp(r'^\+?\d{7,15}$');
  static final RegExp cedulaRegex = RegExp(r'^\d{6,10}$');
  static final RegExp emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  // Igual que nombre/apellido en userValidator.js real (createUserValidator).
  static final RegExp nombreRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
  static final RegExp recoveryCodeRegex = RegExp(r'^\d{4,8}$');
  // cursoController.js real (createCurso/updateCurso, campo `color` nuevo).
  static final RegExp hexColorRegex = RegExp(r'^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
}
