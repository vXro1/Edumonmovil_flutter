import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_extensions.dart';

/// Campo de texto "con formato" sin dependencias de WebView: los botones de
/// la barra insertan marcadores de texto (**negrita**, - lista, ---
/// separador...) sobre un TextField normal — rich_text_lite.dart los
/// convierte al mismo HTML que espera el backend (equivalente mínimo del
/// RichTextEditor.jsx de la web, ver ese archivo para el paralelo exacto).
class RichTextLiteField extends StatelessWidget {
  const RichTextLiteField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.minLines = 3,
    this.maxLines = 8,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int minLines;
  final int? maxLines;

  void _wrapSelection(String left, String right) {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    if (start == end) {
      final newText = text.replaceRange(start, end, '$left$right');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + left.length),
      );
      return;
    }

    final selected = text.substring(start, end);
    final newText = text.replaceRange(start, end, '$left$selected$right');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: start, extentOffset: start + left.length + selected.length + right.length),
    );
  }

  void _insertLinePrefix(String prefix) {
    final sel = controller.selection;
    final text = controller.text;
    final cursor = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', (cursor - 1).clamp(0, text.length)) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: cursor + prefix.length));
  }

  void _insertBlock(String block) {
    final sel = controller.selection;
    final text = controller.text;
    final cursor = sel.isValid ? sel.start : text.length;
    final needsLeadingBreak = cursor > 0 && text[cursor - 1] != '\n';
    final insertText = '${needsLeadingBreak ? '\n\n' : ''}$block\n\n';
    final newText = text.replaceRange(cursor, cursor, insertText);
    controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: cursor + insertText.length));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final borderColor = isDark ? AppColors.borderNormalDark : AppColors.borderNormal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mutedText(context))),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    _ToolbarButton(icon: LucideIcons.bold, tooltip: 'Negrita', onPressed: () => _wrapSelection('**', '**')),
                    _ToolbarButton(icon: LucideIcons.italic, tooltip: 'Cursiva', onPressed: () => _wrapSelection('*', '*')),
                    _ToolbarButton(icon: LucideIcons.underline, tooltip: 'Subrayado', onPressed: () => _wrapSelection('__', '__')),
                    _ToolbarButton(icon: LucideIcons.list, tooltip: 'Lista con viñetas', onPressed: () => _insertLinePrefix('- ')),
                    _ToolbarButton(icon: LucideIcons.listOrdered, tooltip: 'Lista numerada', onPressed: () => _insertLinePrefix('1. ')),
                    _ToolbarButton(icon: LucideIcons.minus, tooltip: 'Separador', onPressed: () => _insertBlock('---')),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              TextField(
                controller: controller,
                minLines: minLines,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 17),
      tooltip: tooltip,
      color: AppColors.mutedText(context),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
