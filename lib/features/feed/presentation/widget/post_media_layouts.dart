import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/feed/presentation/widget/media_viewer_page.dart';
import 'package:tendria/features/feed/presentation/widget/post_style.dart';

/// Varias fotos como mosaico (una grande arriba y pequeñas debajo) o como cuadrícula uniforme.
/// Al tocar una foto se abre el visor a pantalla completa.
class PostMediaGallery extends StatelessWidget {
  final List<PostMediaEntity> media;
  final String layout;

  const PostMediaGallery({super.key, required this.media, required this.layout});

  static const double _gap = 2.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return layout == PostLayouts.mosaic ? _mosaic(context, w) : _grid(context, w);
      },
    );
  }

  Widget _tile(BuildContext context, int index, {int hidden = 0, required double width, required double height}) {
    final item = media[index];
    return GestureDetector(
      onTap: () => MediaViewerPage.open(context, media, index),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.isVideo
                ? Container(
                    color: const Color(0xFF15171C),
                    child: const Center(child: Icon(LucideIcons.circlePlay, color: Colors.white70, size: 38)),
                  )
                : CachedNetworkImage(
                    imageUrl: item.url.replaceAll(' ', '%20'),
                    fit: BoxFit.cover,
                    memCacheWidth: 700,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => ColoredBox(color: FeedStyle.hairline),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: FeedStyle.hairline,
                      child: const Center(child: Icon(LucideIcons.imageOff, size: 28)),
                    ),
                  ),
            if (item.isVideo && hidden == 0)
              const Positioned(right: 8, bottom: 8, child: Icon(LucideIcons.video, size: 16, color: Colors.white)),
            if (hidden > 0)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Text('+$hidden', style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  /// Una foto grande arriba y hasta tres pequeñas debajo.
  Widget _mosaic(BuildContext context, double w) {
    final n = media.length;

    if (n == 2) {
      final half = (w - _gap) / 2;
      return Row(children: [
        _tile(context, 0, width: half, height: w * 0.78),
        const SizedBox(width: _gap),
        _tile(context, 1, width: half, height: w * 0.78),
      ]);
    }

    final below = (n - 1).clamp(1, 3);
    final smallW = (w - _gap * (below - 1)) / below;
    final hidden = n - 4;

    return Column(children: [
      _tile(context, 0, width: w, height: w * 0.68),
      const SizedBox(height: _gap),
      Row(children: [
        for (var i = 0; i < below; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          _tile(context, i + 1, width: smallW, height: smallW, hidden: (i == below - 1 && hidden > 0) ? hidden : 0),
        ],
      ]),
    ]);
  }

  /// Cuadrícula uniforme de hasta 9 fotos: 2 columnas con 2 o 4, y 3 columnas en el resto.
  Widget _grid(BuildContext context, double w) {
    final n = media.length;
    final shown = n > 9 ? 9 : n;
    final cols = (n == 2 || n == 4) ? 2 : 3;
    final size = (w - _gap * (cols - 1)) / cols;
    final hidden = n - shown;

    final rows = <Widget>[];
    for (var start = 0; start < shown; start += cols) {
      final end = (start + cols).clamp(0, shown);
      final count = end - start;
      final tileW = (w - _gap * (count - 1)) / count;
      rows.add(Row(children: [
        for (var i = start; i < end; i++) ...[
          if (i > start) const SizedBox(width: _gap),
          _tile(context, i, width: count == cols ? size : tileW, height: size, hidden: (i == shown - 1 && hidden > 0) ? hidden : 0),
        ],
      ]));
      if (end < shown) rows.add(const SizedBox(height: _gap));
    }
    return Column(children: rows);
  }
}
