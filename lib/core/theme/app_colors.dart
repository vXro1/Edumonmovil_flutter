import 'package:flutter/material.dart';

/// Tokens de color de marca EDUMON — BLUEPRINT.md FASE 2.2.
/// Única fuente de verdad para color en toda la app.
class AppColors {
  const AppColors._();

  // Colores de marca (raw) — paleta oficial EDUMON v2.
  // "Azul" (#0C6AC4) es el primario del dashboard/app en general; "Morado"
  // (#8C38F0) es el color hero de Login/Landing/marca — mismo valor que ya
  // tenía `eduPurple`, lo que cambia es que vuelve a usarse como color
  // protagonista (no solo acento) en esas pantallas puntuales. "Cian"
  // (#05C7F2) es un tono nuevo y distinto del azul primario, reservado para
  // acentos/información — antes ese rol y el de "primario" compartían el
  // mismo valor (#0DC5E2), ya no.
  static const Color eduBlue = Color(0xFF0C6AC4);
  static const Color eduPurple = Color(0xFF8C38F0);
  static const Color eduPink = Color(0xFFF23D7F);
  static const Color eduCyan = Color(0xFF05C7F2);
  static const Color eduGreen = Color(0xFF41D958);
  static const Color eduYellow = Color(0xFFFCBD00);
  static const Color eduCream = Color(0xFFFCF7ED);
  static const Color eduDark = Color(0xFF0D0D0D);
  static const Color eduWhite = Color(0xFFFFFFFF);

  // Escala Blue (primario del dashboard/app)
  static const Color blue50 = Color(0xFFEAF3FC);
  static const Color blue100 = Color(0xFFCCE2F7);
  static const Color blue200 = Color(0xFF9AC5EF);
  static const Color blue300 = Color(0xFF63A4E4);
  static const Color blue400 = Color(0xFF3686D6);
  static const Color blue500 = eduBlue;
  static const Color blue600 = Color(0xFF0A5599);
  static const Color blue700 = Color(0xFF08427A);

  // Escala Purple
  static const Color purple50 = Color(0xFFF7F0FE);
  static const Color purple100 = Color(0xFFEDD9FC);
  static const Color purple200 = Color(0xFFD4ADF9);
  static const Color purple300 = Color(0xFFB87AF5);
  static const Color purple400 = Color(0xFFA057F2);
  static const Color purple500 = eduPurple;
  static const Color purple600 = Color(0xFF7826D8);
  static const Color purple700 = Color(0xFF621BB8);
  static const Color purple800 = Color(0xFF4D1392);
  static const Color purple900 = Color(0xFF360B6B);

  // Escala Pink
  static const Color pink50 = Color(0xFFFEF0F5);
  static const Color pink100 = Color(0xFFFDD9E9);
  static const Color pink200 = Color(0xFFFAA8CC);
  static const Color pink300 = Color(0xFFF675AF);
  static const Color pink400 = Color(0xFFF45194);
  static const Color pink500 = eduPink;
  static const Color pink600 = Color(0xFFD42B68);
  static const Color pink700 = Color(0xFFB01B52);

  // Escala Cyan (acento/información — distinto del azul primario)
  static const Color cyan50 = Color(0xFFE7FAFE);
  static const Color cyan100 = Color(0xFFC3F2FC);
  static const Color cyan200 = Color(0xFF86E4FA);
  static const Color cyan300 = Color(0xFF43D2F5);
  static const Color cyan400 = Color(0xFF19C7F3);
  static const Color cyan500 = eduCyan;
  static const Color cyan600 = Color(0xFF0499BD);
  static const Color cyan700 = Color(0xFF047690);

  // Escala Green
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFD5F7DC);
  static const Color green200 = Color(0xFFA7EEB5);
  static const Color green300 = Color(0xFF71E287);
  static const Color green400 = Color(0xFF55DC6D);
  static const Color green500 = eduGreen;
  static const Color green600 = Color(0xFF2FBD45);
  static const Color green700 = Color(0xFF229D35);

  // Escala Yellow
  static const Color yellow50 = Color(0xFFFFFBEB);
  static const Color yellow100 = Color(0xFFFEF5C7);
  static const Color yellow200 = Color(0xFFFDE88A);
  static const Color yellow300 = Color(0xFFFDD64D);
  static const Color yellow400 = Color(0xFFFCC925);
  static const Color yellow500 = eduYellow;
  static const Color yellow600 = Color(0xFFDFA300);
  static const Color yellow700 = Color(0xFFB88600);

  // Escala Neutral
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral150 = Color(0xFFEFEFEF);
  static const Color neutral200 = Color(0xFFE8E8E8);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // Tokens semánticos — azul de marca como color primario (paleta oficial v2).
  static const Color primary = eduBlue;
  static const Color primaryHover = blue600;
  static const Color primaryLight = blue50;

  static const Color secondary = eduPink;
  static const Color secondaryHover = pink600;
  static const Color secondaryLight = pink50;

  // El morado es el color hero de Login/Landing/marca (EdumonButtonVariant.accent
  // en esas pantallas puntuales) — en el resto de la app funciona como acento.
  static const Color accent = eduPurple;
  static const Color accentHover = purple600;
  static const Color accentLight = purple50;

  /// Acento de información — antes compartía valor con `primary`, ahora es
  /// un cian distinto reservado para badges/íconos informativos.
  static const Color info = eduCyan;
  static const Color infoHover = cyan600;
  static const Color infoLight = cyan50;

  static const Color success = eduGreen;
  static const Color successHover = green600;
  static const Color successLight = green50;

  static const Color warning = eduYellow;
  static const Color warningHover = yellow600;
  static const Color warningLight = yellow50;

  static const Color error = Color(0xFFEF4444);
  static const Color errorHover = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);

  /// Fondo de banners/badges de alerta — los tintes *Light son pasteles
  /// pensados para fondo claro y quedan ilegibles sobre fondo oscuro; en
  /// oscuro se usa el color base con alpha bajo en su lugar.
  static Color errorSurface(bool isDark) => isDark ? error.withValues(alpha: 0.16) : errorLight;
  static Color successSurface(bool isDark) => isDark ? success.withValues(alpha: 0.16) : successLight;
  static Color warningSurface(bool isDark) => isDark ? warning.withValues(alpha: 0.16) : warningLight;

  // Fondos / superficies
  static const Color background = neutral0;
  static const Color backgroundSoft = eduCream;
  static const Color backgroundMuted = neutral50;
  static const Color surface = neutral0;
  static const Color surface2 = neutral50;
  static const Color surface3 = neutral100;

  // Texto
  static const Color textPrimary = eduDark;
  static const Color textMuted = neutral500;
  static const Color textSubtle = neutral400;
  static const Color textInverse = eduWhite;

  /// Variantes de texto secundario que resuelven claro/oscuro según el tema
  /// activo — usar en lugar de `textMuted`/`textSubtle` sueltos fuera de
  /// widgets `const`, donde `textMutedDark`/`textSubtleDark` no se aplicarían.
  static Color mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMutedDark : textMuted;
  static Color subtleText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSubtleDark : textSubtle;

  // Bordes
  static const Color borderNormal = neutral200;
  static const Color borderStrong = neutral300;
  static const Color borderFocus = blue400;

  // Sidebar web — fondo oscuro distintivo (azul marino, no el negro genérico
  // de fondo oscuro), como pide el brief para NAVEGACIÓN WEB.
  static const Color sidebarBg = Color(0xFF0A1B3D);
  static const Color sidebarText = Color(0xCCFFFFFF); // rgba(255,255,255,.8)
  static const Color sidebarActive = eduBlue;

  // Color por sección (sidebar/tabs)
  static const Color sectionInicio = eduBlue;
  static const Color sectionCursos = eduPurple;
  static const Color sectionTareas = eduGreen;
  static const Color sectionForos = eduPink;
  static const Color sectionCalendario = eduYellow;

  // Sombras 3D de botones (offset sólido)
  static const Color shadowBtnPrimary = blue700;
  static const Color shadowBtnSuccess = green700;
  static const Color shadowBtnDanger = Color(0xFFB91C1C);
  static const Color shadowBtnWarning = yellow700;
  static const Color shadowBtnAccent = purple700;

  // Colores extra (no son colores de marca) para diferenciar cursos entre sí
  // en `showEdumonColorPicker` — vivos y distinguibles entre ellos, pensados
  // para complementar los colores de marca en esa paleta puntual.
  static const Color paletteRed = Color(0xFFEF4444);
  static const Color paletteOrange = Color(0xFFF97316);
  static const Color paletteTeal = Color(0xFF14B8A6);
  static const Color paletteBlue = Color(0xFF3B82F6);
  static const Color paletteIndigo = Color(0xFF6366F1);
  static const Color palettePink = Color(0xFFEC4899);
  static const Color paletteLime = Color(0xFF84CC16);
  static const Color paletteSky = Color(0xFF06B6D4);
  static const Color palettePurple = Color(0xFFA855F7);
  static const Color paletteSlate = Color(0xFF64748B);

  static const List<Color> coursePaletteExtras = [
    paletteRed,
    paletteOrange,
    paletteTeal,
    paletteBlue,
    paletteIndigo,
    palettePink,
    paletteLime,
    paletteSky,
    palettePurple,
    paletteSlate,
  ];

  // Modo oscuro — BLUEPRINT.md paleta oficial, fondo #121212 / superficie #1E1E1E.
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundSoftDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surface2Dark = Color(0xFF242424);
  static const Color textPrimaryDark = eduWhite;
  static const Color textMutedDark = Color(0xFFB0B3B8);
  static const Color textSubtleDark = Color(0xFF7A7D82);
  static const Color borderNormalDark = Color(0xFF2A2A2A);
}
