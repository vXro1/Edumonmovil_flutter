import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo de marca EDUMON: ícono del monstruo + wordmark, ambos SVG de la
/// galería (`assets/img/logo/`). Único origen del logo para pantallas
/// de alto impacto (login, olvidé contraseña, wizard de primer ingreso).
class EdumonLogoMark extends StatelessWidget {
  const EdumonLogoMark({
    super.key,
    this.iconSize = 76,
    this.wordmarkWidth = 148,
    this.showWordmark = true,
  });

  final double iconSize;
  final double wordmarkWidth;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/img/logo/logo.svg', height: iconSize),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          SvgPicture.asset('assets/img/logo/titulo.svg', width: wordmarkWidth),
        ],
      ],
    );
  }
}
