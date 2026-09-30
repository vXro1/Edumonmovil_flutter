import 'package:flutter/material.dart';

import '../../utils/rich_text_lite.dart';

/// Renderiza el HTML que guarda el backend (mismo vocabulario que
/// RichTextEditor.jsx en la web: b, i, u, ul, ol, li, p, br, hr) como
/// texto con formato real, en vez de mostrar las etiquetas literales con un
/// Text() plano. Sin dependencia de flutter_html ni WebView — el vocabulario
/// de tags es fijo y chico, así que alcanza con un parser propio simple.
class HtmlLiteView extends StatelessWidget {
  const HtmlLiteView({super.key, required this.html, this.style});

  final String html;
  final TextStyle? style;

  static final _blockPattern = RegExp(
    r'<hr\s*/?>|<ul>.*?</ul>|<ol>.*?</ol>|<p>.*?</p>',
    caseSensitive: false,
    dotAll: true,
  );
  static final _liPattern = RegExp(r'<li>(.*?)</li>', caseSensitive: false, dotAll: true);
  static final _inlinePattern = RegExp(
    r'<br\s*/?>|<(b|strong|i|em|u)>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final matches = _blockPattern.allMatches(html).toList();

    if (matches.isEmpty) {
      // el backend no obliga a que todo venga envuelto en <p> — si no hay
      // ningún bloque reconocible, se trata el string entero como uno solo
      return Text.rich(TextSpan(children: _parseInline(html, baseStyle)));
    }

    final blocks = <Widget>[];
    for (final m in matches) {
      final raw = m.group(0)!;
      final lower = raw.toLowerCase();
      if (lower.startsWith('<hr')) {
        blocks.add(const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)));
      } else if (lower.startsWith('<ul') || lower.startsWith('<ol')) {
        final ordered = lower.startsWith('<ol');
        final items = _liPattern.allMatches(raw).map((li) => li.group(1)!).toList();
        blocks.add(_buildList(items, ordered, baseStyle));
      } else {
        final inner = raw.replaceFirst(RegExp(r'^<p>', caseSensitive: false), '').replaceFirst(RegExp(r'</p>$', caseSensitive: false), '');
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(TextSpan(children: _parseInline(inner, baseStyle))),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: blocks);
  }

  Widget _buildList(List<String> items, bool ordered, TextStyle baseStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(ordered ? '${i + 1}.' : '•', style: baseStyle),
                  ),
                  Expanded(child: Text.rich(TextSpan(children: _parseInline(items[i], baseStyle)))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseInline(String fragment, TextStyle base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inlinePattern.allMatches(fragment)) {
      if (m.start > last) {
        spans.add(TextSpan(text: unescapeHtmlLite(fragment.substring(last, m.start)), style: base));
      }
      if (m.group(0)!.toLowerCase().startsWith('<br')) {
        spans.add(const TextSpan(text: '\n'));
      } else {
        final tag = m.group(1)!.toLowerCase();
        final inner = m.group(2)!;
        final innerStyle = switch (tag) {
          'b' || 'strong' => base.copyWith(fontWeight: FontWeight.bold),
          'i' || 'em' => base.copyWith(fontStyle: FontStyle.italic),
          'u' => base.copyWith(decoration: TextDecoration.underline),
          _ => base,
        };
        spans.addAll(_parseInline(inner, innerStyle));
      }
      last = m.end;
    }
    if (last < fragment.length) {
      spans.add(TextSpan(text: unescapeHtmlLite(fragment.substring(last)), style: base));
    }
    return spans;
  }
}
