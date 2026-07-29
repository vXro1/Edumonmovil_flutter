/// Escala de espaciado — BLUEPRINT.md FASE 2.4 (base 4px).
class AppSpacing {
  const AppSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s14 = 56;
  static const double s16 = 64;
  static const double s20 = 80;
  static const double s24 = 96;
  static const double s32 = 128;

  // Alias semánticos de uso frecuente
  static const double xs = s2;
  static const double sm = s4;
  static const double md = s6;
  static const double lg = s8;
  static const double xl = s12;
}

/// Escala de border-radius — BLUEPRINT.md FASE 2.5.
class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 40;
  static const double full = 9999;
}

/// Duraciones y curvas de animación — BLUEPRINT.md FASE 2.8 / FASE 12.
/// La inconsistencia 120ms/150ms de la web se unifica aquí en un único valor.
class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration spring = Duration(milliseconds: 320);
  static const Duration shake = Duration(milliseconds: 450);
  static const Duration shimmer = Duration(milliseconds: 1400);
}
