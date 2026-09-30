/// Conversión entre el HTML que produce/consume el backend (mismo vocabulario
/// que RichTextEditor.jsx en la web: b, i, u, ul, ol, li, p, br, hr) y una
/// sintaxis de texto plano con marcadores tipo markdown, para poder editarlo
/// en un TextField normal sin meter una dependencia de WebView.
///
///   **negrita**   -> <b>negrita</b>
///   *cursiva*     -> <i>cursiva</i>
///   __subrayado__ -> <u>subrayado</u>
///   - item        -> <li>item</li> dentro de <ul>
///   1. item       -> <li>item</li> dentro de <ol> (el número no importa,
///                    el navegador/el backend re-numeran al renderizar)
///   ---           -> <hr>
///   línea en blanco entre bloques -> separa <p>...</p>
///   salto de línea simple dentro de un bloque -> <br>
library;

final _blankLineSplit = RegExp(r'\n[ \t]*\n');
final _bulletLine = RegExp(r'^-\s+(.*)$');
final _orderedLine = RegExp(r'^\d+\.\s+(.*)$');

String _escapeHtml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// Público: también lo usa HtmlLiteView para renderizar el mismo HTML
/// como texto con formato real en pantallas de solo lectura.
String unescapeHtmlLite(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

/// Negrita/cursiva/subrayado dentro de una línea ya escapada.
String _applyInlineMarkers(String escapedLine) {
  var out = escapedLine;
  out = out.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '<b>${m[1]}</b>');
  out = out.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => '<u>${m[1]}</u>');
  out = out.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => '<i>${m[1]}</i>');
  return out;
}

/// true si el texto plano no tiene contenido visible (solo marcadores/espacios).
bool isRichTextLiteEmpty(String? text) {
  if (text == null) return true;
  final stripped = text.replaceAll(RegExp(r'[\s\-\*_.\d]'), '');
  return stripped.isEmpty;
}

/// Convierte el texto plano con marcadores al HTML que espera el backend.
String richTextLiteToHtml(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';

  final blocks = trimmed.split(_blankLineSplit).map((b) => b.trim()).where((b) => b.isNotEmpty);
  final out = StringBuffer();

  for (final block in blocks) {
    final lines = block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) continue;

    if (lines.length == 1 && lines.first == '---') {
      out.write('<hr>');
      continue;
    }

    final bulletMatches = lines.map((l) => _bulletLine.firstMatch(l)).toList();
    if (bulletMatches.every((m) => m != null)) {
      out.write('<ul>');
      for (final m in bulletMatches) {
        out.write('<li>${_applyInlineMarkers(_escapeHtml(m![1]!))}</li>');
      }
      out.write('</ul>');
      continue;
    }

    final orderedMatches = lines.map((l) => _orderedLine.firstMatch(l)).toList();
    if (orderedMatches.every((m) => m != null)) {
      out.write('<ol>');
      for (final m in orderedMatches) {
        out.write('<li>${_applyInlineMarkers(_escapeHtml(m![1]!))}</li>');
      }
      out.write('</ol>');
      continue;
    }

    final htmlLines = lines.map((l) => _applyInlineMarkers(_escapeHtml(l)));
    out.write('<p>${htmlLines.join('<br>')}</p>');
  }

  return out.toString();
}

/// Convierte el HTML del backend de vuelta a texto plano con marcadores,
/// para poder editar en el TextField un reto que ya tenía descripción
/// (creado desde la web, por ejemplo).
String htmlToRichTextLite(String? html) {
  if (html == null || html.trim().isEmpty) return '';
  var s = html.trim();

  s = s.replaceAll(RegExp(r'<hr\s*/?>', caseSensitive: false), '\n\n---\n\n');

  s = s.replaceAllMapped(
    RegExp(r'<ul>(.*?)</ul>', caseSensitive: false, dotAll: true),
    (m) => '\n\n${_liItemsToLines(m[1]!, ordered: false)}\n\n',
  );
  s = s.replaceAllMapped(
    RegExp(r'<ol>(.*?)</ol>', caseSensitive: false, dotAll: true),
    (m) => '\n\n${_liItemsToLines(m[1]!, ordered: true)}\n\n',
  );

  s = s.replaceAllMapped(
    RegExp(r'<p>(.*?)</p>', caseSensitive: false, dotAll: true),
    (m) => '\n\n${_inlineHtmlToLite(m[1]!)}\n\n',
  );

  // cualquier fragmento fuera de <p>/<ul>/<ol>/<hr> (por si el HTML viene sin
  // envolver en párrafos) se trata igual con los mismos reemplazos inline
  s = _inlineHtmlToLite(s);

  // colapsa 3+ saltos de línea seguidos a como máximo un párrafo en blanco
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

String _liItemsToLines(String ulInnerHtml, {required bool ordered}) {
  final items = RegExp(
    r'<li>(.*?)</li>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(ulInnerHtml);
  final prefix = ordered ? '1. ' : '- ';
  return items.map((m) => '$prefix${_inlineHtmlToLite(m[1]!)}').join('\n');
}

String _inlineHtmlToLite(String html) {
  var s = html;
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAllMapped(RegExp(r'<b>(.*?)</b>', caseSensitive: false, dotAll: true), (m) => '**${m[1]}**');
  s = s.replaceAllMapped(RegExp(r'<strong>(.*?)</strong>', caseSensitive: false, dotAll: true), (m) => '**${m[1]}**');
  s = s.replaceAllMapped(RegExp(r'<u>(.*?)</u>', caseSensitive: false, dotAll: true), (m) => '__${m[1]}__');
  s = s.replaceAllMapped(RegExp(r'<i>(.*?)</i>', caseSensitive: false, dotAll: true), (m) => '*${m[1]}*');
  s = s.replaceAllMapped(RegExp(r'<em>(.*?)</em>', caseSensitive: false, dotAll: true), (m) => '*${m[1]}*');
  // cualquier otra etiqueta que se haya colado (el backend no la sanitiza al
  // guardar) se descarta sin tocar el texto que envuelve
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  return unescapeHtmlLite(s);
}
