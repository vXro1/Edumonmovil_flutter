import 'package:flutter/widgets.dart';

/// Window Size Classes M3 — BLUEPRINT.md FASE 7.
/// compact <600dp · medium 600-839dp · expanded ≥840dp.
/// Usado para decisiones de navegación/layout de alto nivel (Drawer vs
/// NavigationRail, columna única vs multi-columna). Para decidir cuántas
/// columnas mostrar en un grid de cards, usar [Breakpoint.gridColumnsFor]
/// en vez de este enum de 3 valores — un grid necesita más granularidad
/// (una pantalla ultrawide de 2560px y una tablet de 900px son ambas
/// "expanded" acá, pero no deberían mostrar la misma cantidad de columnas).
enum Breakpoint {
  compact,
  medium,
  expanded;

  static Breakpoint of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  static Breakpoint fromWidth(double width) {
    if (width >= 840) return Breakpoint.expanded;
    if (width >= 600) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  bool get isCompact => this == Breakpoint.compact;
  bool get isMedium => this == Breakpoint.medium;
  bool get isExpanded => this == Breakpoint.expanded;
  bool get isMediumOrWider => this != Breakpoint.compact;

  /// true si el ancho es menor a 360dp (móvil muy pequeño) — más angosto que
  /// cualquier caso que [compact] distinga por sí solo.
  static bool isTiny(double width) => width < 360;

  /// Columnas sugeridas para un grid de cards según el ancho disponible —
  /// referencia, no una regla rígida por pantalla:
  /// <600 → 1 · 600–899 → 2 · 900–1199 → 3 · 1200–1599 → 4 · ≥1600 → 5.
  static int gridColumnsFor(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    return 5;
  }
}
