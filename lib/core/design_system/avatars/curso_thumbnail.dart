import 'package:flutter/material.dart';

/// Miniatura circular de portada de curso (`curso.imagenUrl`).
///
/// A diferencia de un `CircleAvatar(backgroundImage: NetworkImage(...))`
/// directo, cae al ícono de respaldo si la imagen falla en vez de dejar la
/// excepción sin manejar (`onBackgroundImageError` ausente) — la falla se
/// repetía en consola en cada repintado y el círculo quedaba en blanco. Es
/// más probable en web: el `<canvas>` de CanvasKit exige cabeceras CORS
/// para pintar imágenes cross-origin, algo que Android/iOS no restringe.
class CursoThumbnail extends StatefulWidget {
  const CursoThumbnail({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String? imageUrl;
  final double radius;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  State<CursoThumbnail> createState() => _CursoThumbnailState();
}

class _CursoThumbnailState extends State<CursoThumbnail> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant CursoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final showImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty && !_failed;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: showImage ? NetworkImage(widget.imageUrl!) : null,
      onBackgroundImageError: showImage ? (_, _) => setState(() => _failed = true) : null,
      child: showImage ? null : Icon(widget.icon, color: widget.iconColor, size: widget.radius * 0.9),
    );
  }
}
