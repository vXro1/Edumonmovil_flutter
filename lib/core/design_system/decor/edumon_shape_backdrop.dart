import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Un shape SVG de la galería (`assets/img/<folder>/`) posicionado en el
/// fondo de una pantalla — usado por [EdumonShapeBackdrop].
class ShapeSpec {
  const ShapeSpec({
    required this.asset,
    required this.size,
    this.folder = 'Shapes',
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.opacity,
    this.rotation = 0,
  });

  /// Nombre de archivo dentro de `assets/img/<folder>/`.
  final String asset;

  /// Subcarpeta bajo `assets/img/` (`Shapes` por defecto, o `circulos`).
  final String folder;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  /// Si es null, usa el [EdumonShapeBackdrop.opacity] por defecto.
  final double? opacity;

  /// Rotación en radianes (variedad orgánica entre shapes repetidos).
  final double rotation;
}

/// Fondo decorativo con shapes SVG de la galería, posicionados detrás del
/// [child]. Pensado para las pantallas de autenticación de alto impacto
/// visual (login, olvidé contraseña, wizard de primer ingreso).
class EdumonShapeBackdrop extends StatelessWidget {
  const EdumonShapeBackdrop({
    super.key,
    required this.child,
    this.opacity = 0.16,
    this.shapes = _defaultShapes,
  });

  final Widget child;

  /// Opacidad por defecto para shapes que no definen la suya propia.
  final double opacity;

  final List<ShapeSpec> shapes;

  static const _defaultShapes = [
    ShapeSpec(asset: 'shape9.svg', size: 96, top: -18, left: -22),
    ShapeSpec(asset: 'shape17.svg', size: 130, top: -8, right: -28),
    ShapeSpec(asset: 'shape20.svg', size: 140, bottom: -28, left: -20),
    ShapeSpec(asset: 'shape11.svg', size: 96, bottom: -16, right: -14),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final spec in shapes)
          Positioned(
            top: spec.top,
            bottom: spec.bottom,
            left: spec.left,
            right: spec.right,
            child: IgnorePointer(
              child: Opacity(
                opacity: spec.opacity ?? opacity,
                child: Transform.rotate(
                  angle: spec.rotation,
                  child: SvgPicture.asset('assets/img/${spec.folder}/${spec.asset}', width: spec.size),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
