
import 'package:flutter/material.dart';

class TapImage extends StatefulWidget {
  const TapImage({
    super.key,
    required this.imageProvider,
    required this.onTapPixel,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  final ImageProvider imageProvider;
  final ValueChanged<Offset> onTapPixel; // x,y in image pixels
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  @override
  State<TapImage> createState() => _TapImageState();
}

class _TapImageState extends State<TapImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imagePx; // intrinsic image size in pixels (w,h)

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(TapImage old) {
    super.didUpdateWidget(old);
    if (old.imageProvider != widget.imageProvider) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    _listener?.let((l) => _stream?.removeListener(l));
    final stream = widget.imageProvider.resolve(const ImageConfiguration());
    _stream = stream;
    _listener = ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      setState(() => _imagePx = Size(w, h));
    });
    stream.addListener(_listener!);
  }

  @override
  void dispose() {
    _listener?.let((l) => _stream?.removeListener(l));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final boxSize = Size(
          widget.width ?? constraints.maxWidth,
          widget.height ?? constraints.maxHeight,
        );

        Widget child = Image(
          image: widget.imageProvider,
          fit: widget.fit,
          alignment: widget.alignment,
          width: widget.width,
          height: widget.height,
          filterQuality: FilterQuality.high,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (_imagePx == null) return; // not resolved yet
            final local = details.localPosition;
            final imageXY = _mapLocalToImagePixels(
              local: local,
              boxSize: boxSize,
              imagePx: _imagePx!,
              fit: widget.fit,
              alignment: widget.alignment,
            );
            if (imageXY != null) {
              widget.onTapPixel(imageXY);
            }
          },
          child: SizedBox(width: boxSize.width, height: boxSize.height, child: child),
        );
      },
    );
  }

  /// Maps a local tap (in box coords) to image pixel coords considering BoxFit.
  /// Returns null if the tap is outside the drawn image area (for letterboxed fits).
  Offset? _mapLocalToImagePixels({
    required Offset local,
    required Size boxSize,
    required Size imagePx,
    required BoxFit fit,
    required Alignment alignment,
  }) {
    final iw = imagePx.width;
    final ih = imagePx.height;
    final bw = boxSize.width;
    final bh = boxSize.height;

    if (iw <= 0 || ih <= 0 || bw <= 0 || bh <= 0) return null;

    switch (fit) {
      case BoxFit.fill:
      // Stretched independently in X and Y.
        final sx = bw / iw;
        final sy = bh / ih;
        final x = local.dx / sx;
        final y = local.dy / sy;
        return Offset(x, y);

      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
      case BoxFit.contain: {
        // Uniform scale that fits entirely, with potential letterboxing
        final scale = fit == BoxFit.fitWidth
            ? (bw / iw)
            : fit == BoxFit.fitHeight
            ? (bh / ih)
            : (bw / iw).clamp(0, double.infinity).compareTo(bh / ih) < 0
            ? (bw / iw)
            : (bh / ih);

        final dw = iw * scale; // drawn image size
        final dh = ih * scale;

        // Alignment shifts inside the box when letterboxed (e.g., center = 0,0)
        final dxMargin = (bw - dw) * (alignment.x + 1) / 2;
        final dyMargin = (bh - dh) * (alignment.y + 1) / 2;

        final xInImageArea = local.dx - dxMargin;
        final yInImageArea = local.dy - dyMargin;

        if (xInImageArea < 0 || yInImageArea < 0 || xInImageArea > dw || yInImageArea > dh) {
          return null; // tapped on letterbox area
        }
        final x = xInImageArea / scale;
        final y = yInImageArea / scale;
        return Offset(x, y);
      }

      case BoxFit.cover: {
        // Uniform scale that fills box; some image area is cropped
        final scale = (bw / iw) > (bh / ih) ? (bw / iw) : (bh / ih);
        final dw = iw * scale;
        final dh = ih * scale;

        // Image is larger than box; compute which part is visible based on alignment
        final overflowX = dw - bw; // >= 0
        final overflowY = dh - bh; // >= 0
        final cropLeft = overflowX * (alignment.x + 1) / 2;
        final cropTop  = overflowY * (alignment.y + 1) / 2;

        // Map local -> image px: first undo scale, then add crop offset
        final x = (local.dx + cropLeft) / scale;
        final y = (local.dy + cropTop)  / scale;
        // Clamp to image bounds
        final xc = x.clamp(0, iw - 1);
        final yc = y.clamp(0, ih - 1);
        return Offset(xc.toDouble(), yc.toDouble());
      }

      case BoxFit.none:
      case BoxFit.scaleDown: {
        // Drawn at natural size (or scaled down if bigger than box), aligned inside box
        final canScale = (iw > bw || ih > bh);
        final scale = (fit == BoxFit.scaleDown && canScale)
            ? (bw / iw).compareTo(bh / ih) < 0 ? (bw / iw) : (bh / ih)
            : 1.0;

        final dw = iw * scale;
        final dh = ih * scale;

        final dxMargin = (bw - dw) * (alignment.x + 1) / 2;
        final dyMargin = (bh - dh) * (alignment.y + 1) / 2;

        final xInImageArea = local.dx - dxMargin;
        final yInImageArea = local.dy - dyMargin;

        if (xInImageArea < 0 || yInImageArea < 0 || xInImageArea > dw || yInImageArea > dh) {
          return null;
        }
        final x = xInImageArea / scale;
        final y = yInImageArea / scale;
        return Offset(x, y);
      }
    }
  }
}

// Tiny "let" extension for cleaner listener removal
extension _ObjLet<T> on T {
  R? let<R>(R Function(T it) f) => f(this);
}
