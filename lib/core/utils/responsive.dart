import 'package:flutter/widgets.dart';

/// Window Size Classes M3 — BLUEPRINT.md FASE 7.
/// compact <600dp · medium 600-839dp · expanded ≥840dp.
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
}
