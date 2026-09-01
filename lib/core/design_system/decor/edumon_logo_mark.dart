import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo de marca EDUMON — BLUEPRINT.md original mostraba el ícono del
/// monstruo + el wordmark "EDUMON" juntos en cada pantalla de alto impacto
/// (login, olvidé/reseteé contraseña, wizard, drawer, footer). Decisión de
/// producto (feedback directo: "exceso de imágenes"): un solo elemento de
/// marca — el wordmark (assets/img/logo/titulo.svg) — sin el ícono. Único
/// origen del logo en toda la app; cambiarlo acá lo cambia en todas partes.
class EdumonLogoMark extends StatelessWidget {
  const EdumonLogoMark({super.key, this.width = 148});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/img/logo/titulo.svg', width: width);
  }
}
