import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/edumon_button.dart';

/// Paleta curada — colores de marca EDUMON primero, después una selección
/// de colores vivos y distinguibles entre sí para diferenciar cursos.
const _paletaSugerida = <Color>[
  AppColors.eduBlue,
  AppColors.eduCyan,
  AppColors.eduPink,
  AppColors.eduPurple,
  AppColors.eduGreen,
  AppColors.eduYellow,
  ...AppColors.coursePaletteExtras,
];

/// Convierte un [Color] a `#RRGGBB` (mayúsculas), el formato que espera el
/// backend (`AppConstants.hexColorRegex`).
String colorToHex(Color color) {
  final r = ((color.r * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final g = ((color.g * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final b = ((color.b * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

Color? colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var value = hex.replaceFirst('#', '');
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

/// Abre el selector visual de color de EDUMON (paleta + rueda cromática) y
/// devuelve el color elegido, o `null` si el usuario canceló.
///
/// El usuario nunca ve ni escribe un código hexadecimal — el widget se
/// encarga de convertir la selección visual a `#RRGGBB` internamente
/// (ver [colorToHex]), que es el único formato que toca el resto de la app.
Future<Color?> showEdumonColorPicker(BuildContext context, {Color? initialColor}) {
  return showDialog<Color>(
    context: context,
    builder: (context) => _EdumonColorPickerDialog(initialColor: initialColor ?? AppColors.eduBlue),
  );
}

class _EdumonColorPickerDialog extends StatefulWidget {
  const _EdumonColorPickerDialog({required this.initialColor});
  final Color initialColor;

  @override
  State<_EdumonColorPickerDialog> createState() => _EdumonColorPickerDialogState();
}

class _EdumonColorPickerDialogState extends State<_EdumonColorPickerDialog> with SingleTickerProviderStateMixin {
  late Color _selected = widget.initialColor;
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // maxHeight fijo (560) desbordaba en pantallas bajas (ej. 320×568, donde
    // insetPadding vertical + el resto del chrome del diálogo ya dejaban
    // menos que eso disponible) — se acota al alto real de la ventana.
    final maxDialogHeight = (MediaQuery.sizeOf(context).height * 0.9).clamp(320.0, 560.0);
    // ~260px de chrome fijo (preview + tabs + spacing + botones) alrededor
    // del contenido de la tab — el resto se lo queda el TabBarView.
    final tabAreaHeight = (maxDialogHeight - 260).clamp(160.0, 300.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Container(
        constraints: BoxConstraints(maxWidth: 380, maxHeight: maxDialogHeight),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: isDark ? Border.all(color: AppColors.borderNormalDark) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vista previa en tiempo real del color elegido.
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _selected,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.borderNormalDark : AppColors.borderNormal,
                      width: 2,
                    ),
                    boxShadow: [BoxShadow(color: _selected.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Color del curso',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.mutedText(context),
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Paleta'),
                Tab(text: 'Personalizado'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: tabAreaHeight,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _paletaTab(),
                  _ruedaTab(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: EdumonButton(
                    label: 'Cancelar',
                    variant: EdumonButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EdumonButton(
                    label: 'Usar este color',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(_selected),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paletaTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Columnas calculadas según el ancho real del diálogo en vez de un
        // número fijo — 5 quedaba ajustado en pantallas angostas (el diálogo
        // se achica con `insetPadding`, no siempre tiene los 380 de maxWidth).
        const targetSwatchSize = 52.0;
        final columns = (constraints.maxWidth / targetSwatchSize).floor().clamp(3, 6);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          itemCount: _paletaSugerida.length,
          itemBuilder: (context, i) {
            final color = _paletaSugerida[i];
            final selected = color.toARGB32() == _selected.toARGB32();
            return Semantics(
              button: true,
              selected: selected,
              label: 'Color ${colorToHex(color)}',
              child: GestureDetector(
                onTap: () => setState(() => _selected = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: AppColors.textInverse, width: 3) : null,
                    boxShadow: selected
                        ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                  child: selected ? const Icon(Icons.check, color: AppColors.textInverse, size: 18) : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ruedaTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          HueRingPicker(
            pickerColor: _selected,
            onColorChanged: (color) => setState(() => _selected = color),
            displayThumbColor: true,
            enableAlpha: false,
          ),
        ],
      ),
    );
  }
}
