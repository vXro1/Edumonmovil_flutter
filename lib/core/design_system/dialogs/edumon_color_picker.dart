import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/edumon_button.dart';

/// Paleta curada — colores de marca EDUMON primero, después una selección
/// de colores vivos y distinguibles entre sí para diferenciar cursos.
const _paletaSugerida = <Color>[
  AppColors.eduCyan,
  AppColors.eduPink,
  AppColors.eduPurple,
  AppColors.eduGreen,
  AppColors.eduYellow,
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFF14B8A6),
  Color(0xFF3B82F6),
  Color(0xFF6366F1),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
  Color(0xFF06B6D4),
  Color(0xFFA855F7),
  Color(0xFF64748B),
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
    builder: (context) => _EdumonColorPickerDialog(initialColor: initialColor ?? AppColors.eduCyan),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 560),
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
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 2),
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
              height: 300,
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
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
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
                border: selected ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: selected
                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ),
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
