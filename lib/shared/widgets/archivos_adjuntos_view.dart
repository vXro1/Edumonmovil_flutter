import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../models/archivo.dart';
import 'abrir_archivo_web.dart' if (dart.library.io) 'abrir_archivo_io.dart';

/// Descarga un adjunto con el Dio de la app (lleva la cookie de sesión): los
/// adjuntos privados de entregas (/uploads/priv) responden 401 a un
/// Image.network o a un navegador externo sin sesión.
final archivoBytesProvider = FutureProvider.family<Uint8List, String>((ref, url) async {
  final dio = ref.watch(apiClientProvider).dio;
  final response = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
  return Uint8List.fromList(response.data ?? const []);
});

/// Lista de adjuntos de un reto/entrega: imágenes en miniatura dentro de la
/// app (tocar = pantalla completa con zoom), PDF/video/otros descargables y
/// enlaces externos que se abren en el navegador.
class ArchivosAdjuntosView extends StatelessWidget {
  const ArchivosAdjuntosView({super.key, required this.archivos, this.onDelete});

  final List<Archivo> archivos;

  /// Si se pasa, cada adjunto muestra un botón para quitarlo.
  final ValueChanged<Archivo>? onDelete;

  @override
  Widget build(BuildContext context) {
    final imagenes = archivos.where((a) => a.esImagen).toList();
    final otros = archivos.where((a) => !a.esImagen).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imagenes.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final unaSola = imagenes.length == 1;
              final lado = unaSola ? constraints.maxWidth : (constraints.maxWidth - AppSpacing.xs * 2) / 3;
              return Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (var i = 0; i < imagenes.length; i++)
                    SizedBox(
                      width: lado,
                      height: unaSola ? 220 : lado,
                      child: _ImagenThumb(
                        archivo: imagenes[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ImagenesViewerScreen(imagenes: imagenes, inicial: i),
                          ),
                        ),
                        onDelete: onDelete == null ? null : () => onDelete!(imagenes[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        if (imagenes.isNotEmpty && otros.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        for (final a in otros)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ArchivoTile(archivo: a, onDelete: onDelete == null ? null : () => onDelete!(a)),
          ),
      ],
    );
  }
}

class _ImagenThumb extends ConsumerWidget {
  const _ImagenThumb({required this.archivo, required this.onTap, this.onDelete});

  final Archivo archivo;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(archivoBytesProvider(archivo.url));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Imagen ${archivo.nombre}. Toca para verla completa',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Material(
              color: isDark ? AppColors.surface2Dark : AppColors.neutral100,
              child: InkWell(
                onTap: onTap,
                child: bytes.when(
                  data: (b) => Hero(tag: 'img-${archivo.url}', child: Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true)),
                  loading: () => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, _) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.imageOff, color: AppColors.mutedText(context)),
                      TextButton(
                        onPressed: () => ref.invalidate(archivoBytesProvider(archivo.url)),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                    tooltip: 'Quitar ${archivo.nombre}',
                    onPressed: onDelete,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArchivoTile extends ConsumerStatefulWidget {
  const _ArchivoTile({required this.archivo, this.onDelete});

  final Archivo archivo;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_ArchivoTile> createState() => _ArchivoTileState();
}

class _ArchivoTileState extends ConsumerState<_ArchivoTile> {
  bool _abriendo = false;

  IconData get _icon {
    final a = widget.archivo;
    if (a.esEnlace) return LucideIcons.link;
    if (a.esPdf) return LucideIcons.fileText;
    if (a.esVideo) return LucideIcons.video;
    return LucideIcons.file;
  }

  String get _subtitulo {
    final a = widget.archivo;
    if (a.esEnlace) return a.descripcion?.isNotEmpty == true ? a.descripcion! : a.url;
    final partes = [
      if (a.esPdf) 'PDF' else if (a.esVideo) 'Video' else if (a.extension.isNotEmpty) a.extension.toUpperCase(),
      ?a.tamanoLegible,
    ];
    return partes.join(' · ');
  }

  Future<void> _abrir() async {
    final a = widget.archivo;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _abriendo = true);
    String? error;
    try {
      if (a.esEnlace) {
        final uri = Uri.tryParse(a.url);
        final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) error = 'No se pudo abrir el enlace.';
      } else if (kIsWeb) {
        error = await abrirArchivoLocal(Uint8List(0), a.nombre, a.url);
      } else {
        final bytes = await ref.read(archivoBytesProvider(a.url).future);
        error = await abrirArchivoLocal(bytes, a.nombre.contains('.') ? a.nombre : '${a.nombre}.${a.extension}', a.url);
      }
    } catch (_) {
      ref.invalidate(archivoBytesProvider(a.url));
      error = 'No se pudo descargar el archivo. Revisa tu conexión e intenta de nuevo.';
    }
    if (!mounted) return;
    setState(() => _abriendo = false);
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.archivo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accion = a.esEnlace ? 'Abrir enlace' : 'Abrir archivo';
    return Material(
      color: isDark ? AppColors.surface2Dark : AppColors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: isDark ? AppColors.borderNormalDark : AppColors.borderNormal),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abriendo ? null : _abrir,
        child: Semantics(
          button: true,
          label: '$accion ${a.nombre}',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(_icon, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (_subtitulo.isNotEmpty)
                        Text(
                          _subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (_abriendo)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(a.esEnlace ? LucideIcons.externalLink : LucideIcons.download, size: 20, color: AppColors.mutedText(context)),
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                    tooltip: 'Quitar ${a.nombre}',
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Visor de imágenes a pantalla completa (deslizar entre imágenes, pellizcar
/// para hacer zoom). Todo dentro de la app — el usuario no sale a un navegador.
class ImagenesViewerScreen extends ConsumerStatefulWidget {
  const ImagenesViewerScreen({super.key, required this.imagenes, this.inicial = 0});

  final List<Archivo> imagenes;
  final int inicial;

  @override
  ConsumerState<ImagenesViewerScreen> createState() => _ImagenesViewerScreenState();
}

class _ImagenesViewerScreenState extends ConsumerState<ImagenesViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imagenes.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          total > 1 ? '${_actual + 1} de $total · ${widget.imagenes[_actual].nombre}' : widget.imagenes[_actual].nombre,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: total,
        onPageChanged: (i) => setState(() => _actual = i),
        itemBuilder: (context, i) {
          final a = widget.imagenes[i];
          final bytes = ref.watch(archivoBytesProvider(a.url));
          return bytes.when(
            data: (b) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: 'img-${a.url}',
                  child: Image.memory(b, fit: BoxFit.contain, semanticLabel: a.nombre),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(archivoBytesProvider(a.url)),
                child: const Text('No se pudo cargar la imagen. Reintentar', style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}
