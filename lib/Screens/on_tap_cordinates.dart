
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../ffi_bridge/ffi_binding.dart';


import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Widget pane(
    Uint8List? bytes, {
      ValueChanged<Offset>? onTapPixel,
      List<BulletHole>? bulletHoles,
      double? ringDiameterPixels,
      Offset? groupCenter,
      double? groupRadius,
      Offset? highlightBulletHole,
      required bool isTitleBulletHole,
      GlobalKey? repaintBoundaryKey,
      Function(int index, Offset startCoord)? onRingDragStart,
      Function(int index, Offset endCoord, bool isDeleted)? onRingDragEnd,
    }) {
  return _TapPane(
    bytes: bytes,
    onTapPixel: onTapPixel,
    bulletHoles: bulletHoles,
    ringDiameterPixels: ringDiameterPixels,
    groupCenter: groupCenter,
    groupRadius: groupRadius,
    highlightBulletHole: highlightBulletHole,
    isTitleBulletHole: isTitleBulletHole,
    repaintBoundaryKey: repaintBoundaryKey,
    onRingDragStart: onRingDragStart,
    onRingDragEnd: onRingDragEnd,
  );
}

class _TapPane extends StatefulWidget {
  final Uint8List? bytes;
  final ValueChanged<Offset>? onTapPixel;
  final List<BulletHole>? bulletHoles;
  final double? ringDiameterPixels;
  final Offset? groupCenter;
  final double? groupRadius;
  final Offset? highlightBulletHole;
  final bool isTitleBulletHole;
  final GlobalKey? repaintBoundaryKey;
  final Function(int index, Offset startCoord)? onRingDragStart;
  final Function(int index, Offset endCoord, bool isDeleted)? onRingDragEnd;

  const _TapPane({
    super.key,
    this.bytes,
    this.onTapPixel,
    this.bulletHoles,
    this.ringDiameterPixels,
    this.groupCenter,
    this.groupRadius,
    this.highlightBulletHole,
    this.repaintBoundaryKey,
    required this.isTitleBulletHole,
    this.onRingDragStart,
    this.onRingDragEnd,
  });

  @override
  State<_TapPane> createState() => _TapPaneState();
}

class _TapPaneState extends State<_TapPane> with SingleTickerProviderStateMixin {
  ui.Image? _image;
  bool _imageLoaded = false;
  final TransformationController _transformationController = TransformationController();
  AnimationController? _arrowAnimationController;
  Animation<double>? _arrowAnimation;

  int? _draggedRingIndex;
  Offset? _draggedRingPosition;      // image coords
  Offset? _draggedRingStartPosition; // image coords

  bool _showDeleteIcon = false;

  // Track GLOBAL position for robust hit-test against the delete icon box
  Offset? _currentDragGlobalPosition;

  // Key for the delete icon container
  final GlobalKey _deleteIconKey = GlobalKey();

  final double _deleteIconSize = 50.0;

  @override
  void initState() {
    super.initState();
    _loadImage();

    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _arrowAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _arrowAnimationController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TapPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.bytes == null) {
      setState(() {
        _image = null;
        _imageLoaded = false;
      });
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(widget.bytes!);
      final frame = await codec.getNextFrame();
      if (frame.image.width > 0 && frame.image.height > 0) {
        setState(() {
          _image = frame.image;
          _imageLoaded = true;
        });
      } else {
        setState(() {
          _image = null;
          _imageLoaded = false;
        });
      }
    } catch (_) {
      setState(() {
        _image = null;
        _imageLoaded = false;
      });
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!_imageLoaded || _image == null) return;

    // Transform to pan-space for hit testing rings on the image
    final Matrix4 inverse = Matrix4.inverted(_transformationController.value);
    final localForPan = MatrixUtils.transformPoint(inverse, details.localPosition);

    final tappedRingIndex = _findRingAtPosition(localForPan);

    if (tappedRingIndex != null) {
      final imageCoordinates = _screenToImageCoordinates(localForPan);

      setState(() {
        _draggedRingIndex = tappedRingIndex;
        _draggedRingPosition = imageCoordinates;
        _draggedRingStartPosition = imageCoordinates;
        _showDeleteIcon = true;
        _currentDragGlobalPosition = details.globalPosition; // store GLOBAL
      });

      widget.onRingDragStart?.call(tappedRingIndex, imageCoordinates);
    } else {
      final imageCoordinates = _screenToImageCoordinates(localForPan);
      if (widget.onTapPixel != null &&
          imageCoordinates.dx.isFinite &&
          imageCoordinates.dy.isFinite &&
          imageCoordinates.dx >= 0 &&
          imageCoordinates.dy >= 0) {
        widget.onTapPixel!(imageCoordinates);
      }
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_draggedRingIndex != null) {
      final Matrix4 inverse = Matrix4.inverted(_transformationController.value);
      final localForPan = MatrixUtils.transformPoint(inverse, details.localPosition);
      final imageCoordinates = _screenToImageCoordinates(localForPan);

      setState(() {
        _draggedRingPosition = imageCoordinates;
        _currentDragGlobalPosition = details.globalPosition; // keep GLOBAL updated
      });
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_draggedRingIndex == null) return;

    bool isDeleted = _isOverDeleteIconGlobal();
    Offset finalCoord = _draggedRingPosition!;

    if (isDeleted) {
      // On delete, report the start position (your original logic)
      finalCoord = _draggedRingStartPosition!;
    }

    widget.onRingDragEnd?.call(_draggedRingIndex!, finalCoord, isDeleted);

    setState(() {
      _draggedRingIndex = null;
      _draggedRingPosition = null;
      _draggedRingStartPosition = null;
      _showDeleteIcon = false;
      _currentDragGlobalPosition = null;
    });
  }

  // Hit-test: convert the GLOBAL pointer to the delete icon's LOCAL space
  bool _isOverDeleteIconGlobal() {
    if (_currentDragGlobalPosition == null) return false;
    final ctx = _deleteIconKey.currentContext;
    if (ctx == null) return false;

    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final Size size = box.size;

    // Convert the global pointer to the delete icon's local coordinates
    final Offset localInDelete = box.globalToLocal(_currentDragGlobalPosition!);

    // Use an inflated rect for friendlier drops
    final Rect rect = Offset.zero & size;
    return rect.inflate(8).contains(localInDelete);
  }

  int? _findRingAtPosition(Offset screenPositionInPanSpace) {
    if (!_imageLoaded || _image == null || widget.bulletHoles == null) return null;

    final imageCoordinates = _screenToImageCoordinates(screenPositionInPanSpace);
    final tapRadius = widget.ringDiameterPixels ?? 9.08;

    for (int i = 0; i < widget.bulletHoles!.length; i++) {
      final hole = widget.bulletHoles![i];
      final holePosition = Offset(hole.cxPx, hole.cyPx);
      final distance = (imageCoordinates - holePosition).distance;

      if (distance <= tapRadius * 1.5) {
        return i;
      }
    }
    return null;
  }

  Offset _screenToImageCoordinates(Offset screenPositionInPanSpace) {
    if (!_imageLoaded || _image == null) return Offset.zero;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final containerSize = renderBox.size;
    if (containerSize.width <= 0 || containerSize.height <= 0) return Offset.zero;
    if (_image!.width <= 0 || _image!.height <= 0) return Offset.zero;

    final imageWidth = _image!.width.toDouble();
    final imageHeight = _image!.height.toDouble();
    final containerWidth = containerSize.width;
    final containerHeight = containerSize.height;

    final imageAR = imageWidth / imageHeight;
    final containerAR = containerWidth / containerHeight;
    if (!imageAR.isFinite || !containerAR.isFinite) return Offset.zero;

    late double displayWidth, displayHeight, displayOffsetX, displayOffsetY;
    if (imageAR > containerAR) {
      displayWidth = containerWidth;
      displayHeight = containerWidth / imageAR;
      displayOffsetX = 0;
      displayOffsetY = (containerHeight - displayHeight) / 2;
    } else {
      displayWidth = containerHeight * imageAR;
      displayHeight = containerHeight;
      displayOffsetX = (containerWidth - displayWidth) / 2;
      displayOffsetY = 0;
    }

    if (displayWidth <= 0 || displayHeight <= 0) return Offset.zero;

    final relativeX = (screenPositionInPanSpace.dx - displayOffsetX) / displayWidth;
    final relativeY = (screenPositionInPanSpace.dy - displayOffsetY) / displayHeight;
    if (!relativeX.isFinite || !relativeY.isFinite) return Offset.zero;

    final imageX = (relativeX * imageWidth).clamp(0.0, imageWidth);
    final imageY = (relativeY * imageHeight).clamp(0.0, imageHeight);
    return Offset(imageX, imageY);
  }

  bool _isOverDeleteIconHover() {
    // For hover visuals during drag (same logic as drop)
    if (_currentDragGlobalPosition == null) return false;
    final ctx = _deleteIconKey.currentContext;
    if (ctx == null) return false;

    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final Size size = box.size;
    final Offset localInDelete = box.globalToLocal(_currentDragGlobalPosition!);
    return (Offset.zero & size).inflate(8).contains(localInDelete);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque, // ensure we keep getting events
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressMoveUpdate,
          onLongPressEnd: _onLongPressEnd,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                if (_imageLoaded && _image != null)
                  RepaintBoundary(
                    key: widget.repaintBoundaryKey,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 50.0,
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: _arrowAnimation != null
                            ? AnimatedBuilder(
                          animation: _arrowAnimation!,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _ImagePainter(
                                _image!,
                                widget.isTitleBulletHole,
                                bulletHoles: widget.bulletHoles,
                                ringDiameterPixels: widget.ringDiameterPixels,
                                groupCenter: widget.groupCenter,
                                groupRadius: widget.groupRadius,
                                highlightBulletHole: widget.highlightBulletHole,
                                arrowOffset: _arrowAnimation!.value,
                                draggedRingIndex: _draggedRingIndex,
                                draggedRingPosition: _draggedRingPosition,
                              ),
                              size: Size(width, height),
                            );
                          },
                        )
                            : CustomPaint(
                          painter: _ImagePainter(
                            _image!,
                            widget.isTitleBulletHole,
                            bulletHoles: widget.bulletHoles,
                            ringDiameterPixels: widget.ringDiameterPixels,
                            groupCenter: widget.groupCenter,
                            groupRadius: widget.groupRadius,
                            highlightBulletHole: widget.highlightBulletHole,
                            arrowOffset: 0.0,
                            draggedRingIndex: _draggedRingIndex,
                            draggedRingPosition: _draggedRingPosition,
                          ),
                          size: Size(width, height),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                    ),
                  ),

                // Delete icon (top-right) with a key for precise hit tests
                if (_showDeleteIcon)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: AnimatedContainer(
                      key: _deleteIconKey,
                      duration: const Duration(milliseconds: 200),
                      width: _deleteIconSize,
                      height: _deleteIconSize,
                      decoration: BoxDecoration(
                        color: _isOverDeleteIconHover()
                            ? Colors.red.withOpacity(0.95)
                            : Colors.red.withOpacity(0.75),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                        size: _isOverDeleteIconHover() ? 32 : 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<BulletHole>? bulletHoles;
  final double? ringDiameterPixels;
  final Offset? groupCenter;
  final double? groupRadius;
  final Offset? highlightBulletHole;
  final double arrowOffset;
  final bool isTitleBulletHole;
  final int? draggedRingIndex;
  final Offset? draggedRingPosition; // image coords

  _ImagePainter(
      this.image,
      this.isTitleBulletHole, {
        this.bulletHoles,
        this.ringDiameterPixels,
        this.groupCenter,
        this.groupRadius,
        this.highlightBulletHole,
        this.arrowOffset = 0.0,
        this.draggedRingIndex,
        this.draggedRingPosition,
      });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || image.width <= 0 || image.height <= 0) return;

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final canvasWidth = size.width;
    final canvasHeight = size.height;

    final imageAR = imageWidth / imageHeight;
    final canvasAR = canvasWidth / canvasHeight;
    if (!imageAR.isFinite || !canvasAR.isFinite) return;

    late Rect srcRect, dstRect;
    late double displayWidth, displayHeight, displayOffsetX, displayOffsetY;

    if (imageAR > canvasAR) {
      displayHeight = canvasWidth / imageAR;
      displayOffsetY = (canvasHeight - displayHeight) / 2;
      displayOffsetX = 0;
      displayWidth = canvasWidth;
      srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      dstRect = Rect.fromLTWH(0, displayOffsetY, canvasWidth, displayHeight);
    } else {
      displayWidth = canvasHeight * imageAR;
      displayOffsetX = (canvasWidth - displayWidth) / 2;
      displayOffsetY = 0;
      displayHeight = canvasHeight;
      srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      dstRect = Rect.fromLTWH(displayOffsetX, 0, displayWidth, canvasHeight);
    }

    if (dstRect.width > 0 && dstRect.height > 0) {
      canvas.drawImageRect(image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
    }

    if (bulletHoles != null && bulletHoles!.isNotEmpty) {
      for (int i = 0; i < bulletHoles!.length; i++) {
        final hole = bulletHoles![i];

        final holeImagePos = (draggedRingIndex == i && draggedRingPosition != null)
            ? draggedRingPosition!
            : Offset(hole.cxPx, hole.cyPx);

        final screenCoord = _imageToScreenCoordinates(
          holeImagePos,
          imageWidth,
          imageHeight,
          displayWidth,
          displayHeight,
          displayOffsetX,
          displayOffsetY,
        );

        final radius = ringDiameterPixels != null
            ? (ringDiameterPixels ?? 9.08) * (displayWidth / imageWidth)
            : 5.0;

        final ringPaint = Paint()
          ..color = (draggedRingIndex == i) ? Colors.blue : _getColorForScore(hole.score)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (draggedRingIndex == i) ? 1.5 : 0.8;

        canvas.drawCircle(screenCoord, radius, ringPaint);

        // Label
        if (isTitleBulletHole) {
          final textSpan = const TextSpan(
            // You can customize label text if needed
            style: TextStyle(
              color: Colors.deepOrangeAccent,
              fontSize: 6,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0.5, 0.5)),
              ],
            ),
          );
          final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
          textPainter.layout();
          final textOffset = Offset(screenCoord.dx - (textPainter.width / 2), screenCoord.dy - radius - textPainter.height - 1);
          // You used 'S-${hole.index}' earlier; if needed, add it back:
          final label = TextPainter(
            text: TextSpan(
              text: 'S-${hole.index}',
              style: const TextStyle(
                color: Colors.deepOrangeAccent,
                fontSize: 6,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0.5, 0.5))],
              ),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, textOffset);
        }
      }
    }

    if (highlightBulletHole != null) {
      final target = _imageToScreenCoordinates(
        highlightBulletHole!,
        imageWidth,
        imageHeight,
        displayWidth,
        displayHeight,
        displayOffsetX,
        displayOffsetY,
      );
      _drawArrow(canvas, target, arrowOffset);
    }

    if (groupCenter != null && groupRadius != null) {
      final c = _imageToScreenCoordinates(
        groupCenter!,
        imageWidth,
        imageHeight,
        displayWidth,
        displayHeight,
        displayOffsetX,
        displayOffsetY,
      );
      final paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(c, groupRadius! * (displayWidth / imageWidth), paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset target, double offset) {
    final arrowPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    final stroke = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;

    const s = 15.0;
    final tip = Offset(target.dx, target.dy - 5 - offset);
    final left = Offset(target.dx - s / 2, target.dy - 60 - offset);
    final right = Offset(target.dx + s / 2, target.dy - 60 - offset);
    final back = Offset(target.dx, target.dy - 50 - offset);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(back.dx, back.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, stroke);
    canvas.drawPath(path, arrowPaint);
  }

  Color _getColorForScore(int score) => Colors.orange;

  Offset _imageToScreenCoordinates(
      Offset imageCoord,
      double imageWidth,
      double imageHeight,
      double displayWidth,
      double displayHeight,
      double displayOffsetX,
      double displayOffsetY,
      ) {
    final rx = imageCoord.dx / imageWidth;
    final ry = imageCoord.dy / imageHeight;
    return Offset(displayOffsetX + rx * displayWidth, displayOffsetY + ry * displayHeight);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter old) {
    return old.image != image ||
        old.bulletHoles != bulletHoles ||
        old.ringDiameterPixels != ringDiameterPixels ||
        old.groupCenter != groupCenter ||
        old.groupRadius != groupRadius ||
        old.highlightBulletHole != highlightBulletHole ||
        old.arrowOffset != arrowOffset ||
        old.draggedRingIndex != draggedRingIndex ||
        old.draggedRingPosition != draggedRingPosition;
  }
}




//
// Widget pane(
//     Uint8List? bytes, {
//       ValueChanged<Offset>? onTapPixel,
//       List<BulletHole>? bulletHoles,
//       double? ringDiameterPixels,
//       Offset? groupCenter,
//       double? groupRadius,
//       Offset? highlightBulletHole,
//       required bool isTitleBulletHole,
//       GlobalKey? repaintBoundaryKey,
//     }) {
//   return _TapPane(
//     bytes: bytes,
//     onTapPixel: onTapPixel,
//     bulletHoles: bulletHoles,
//     ringDiameterPixels: ringDiameterPixels,
//     groupCenter: groupCenter,
//     groupRadius: groupRadius,
//     highlightBulletHole: highlightBulletHole,
//     isTitleBulletHole: isTitleBulletHole,
//     repaintBoundaryKey: repaintBoundaryKey,
//   );
// }
//
// class _TapPane extends StatefulWidget {
//   final Uint8List? bytes;
//   final ValueChanged<Offset>? onTapPixel;
//   final List<BulletHole>? bulletHoles;
//   final double? ringDiameterPixels;
//   final Offset? groupCenter;
//   final double? groupRadius;
//   final Offset? highlightBulletHole;
//   final bool isTitleBulletHole;
//   final GlobalKey? repaintBoundaryKey;
//
//   const _TapPane({
//     super.key,
//     this.bytes,
//     this.onTapPixel,
//     this.bulletHoles,
//     this.ringDiameterPixels,
//     this.groupCenter,
//     this.groupRadius,
//     this.highlightBulletHole,
//     this.repaintBoundaryKey, required this.isTitleBulletHole,
//   });
//
//   @override
//   State<_TapPane> createState() => _TapPaneState();
// }
//
// class _TapPaneState extends State<_TapPane> with SingleTickerProviderStateMixin {
//   Offset? _magnifierPosition;
//   bool _showMagnifier = false;
//   ui.Image? _image;
//   bool _imageLoaded = false;
//   final TransformationController _transformationController = TransformationController();
//   AnimationController? _arrowAnimationController;
//   Animation<double>? _arrowAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadImage();
//
//     // Initialize arrow animation
//     _arrowAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     )..repeat(reverse: true);
//
//     _arrowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
//       CurvedAnimation(
//         parent: _arrowAnimationController!,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _transformationController.dispose();
//     _arrowAnimationController?.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didUpdateWidget(_TapPane oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.bytes != widget.bytes) {
//       _loadImage();
//     }
//   }
//
//   Future<void> _loadImage() async {
//     if (widget.bytes == null) {
//       setState(() {
//         _image = null;
//         _imageLoaded = false;
//       });
//       return;
//     }
//
//     try {
//       final codec = await ui.instantiateImageCodec(widget.bytes!);
//       final frame = await codec.getNextFrame();
//
//       // Validate image dimensions
//       if (frame.image.width > 0 && frame.image.height > 0) {
//         setState(() {
//           _image = frame.image;
//           _imageLoaded = true;
//         });
//       } else {
//         setState(() {
//           _image = null;
//           _imageLoaded = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _image = null;
//         _imageLoaded = false;
//       });
//     }
//   }
//
//   void _onLongPressStart(LongPressStartDetails details) {
//     if (!_imageLoaded || _image == null) return;
//
//     setState(() {
//       _magnifierPosition = details.localPosition;
//       _showMagnifier = true;
//     });
//   }
//
//   void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
//     setState(() {
//       _magnifierPosition = details.localPosition;
//     });
//   }
//
//   void _onLongPressEnd(LongPressEndDetails details) {
//     _reportCoordinates(_magnifierPosition!);
//
//     setState(() {
//       _showMagnifier = false;
//       _magnifierPosition = null;
//     });
//   }
//
//   void _onTapDown(TapDownDetails details) {
//     _reportCoordinates(details.localPosition);
//   }
//
//   void _reportCoordinates(Offset position) {
//     if (widget.onTapPixel != null && _imageLoaded && _image != null) {
//       final Matrix4 inverse = Matrix4.inverted(_transformationController.value);
//       final localPosition = MatrixUtils.transformPoint(inverse, position);
//
//       final imageCoordinates = _screenToImageCoordinates(localPosition);
//
//       if (imageCoordinates.dx.isFinite &&
//           imageCoordinates.dy.isFinite &&
//           imageCoordinates.dx >= 0 &&
//           imageCoordinates.dy >= 0) {
//         widget.onTapPixel!(imageCoordinates);
//       }
//     }
//   }
//
//   Offset _screenToImageCoordinates(Offset screenPosition) {
//     if (!_imageLoaded || _image == null) return Offset.zero;
//
//     final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
//     if (renderBox == null) return Offset.zero;
//
//     final containerSize = renderBox.size;
//
//     if (containerSize.width <= 0 || containerSize.height <= 0) {
//       return Offset.zero;
//     }
//
//     if (_image!.width <= 0 || _image!.height <= 0) {
//       return Offset.zero;
//     }
//
//     final imageWidth = _image!.width.toDouble();
//     final imageHeight = _image!.height.toDouble();
//     final containerWidth = containerSize.width;
//     final containerHeight = containerSize.height;
//
//     final imageAspectRatio = imageWidth / imageHeight;
//     final containerAspectRatio = containerWidth / containerHeight;
//
//     if (!imageAspectRatio.isFinite || !containerAspectRatio.isFinite) {
//       return Offset.zero;
//     }
//
//     late double displayWidth, displayHeight, displayOffsetX, displayOffsetY;
//
//     if (imageAspectRatio > containerAspectRatio) {
//       displayWidth = containerWidth;
//       displayHeight = containerWidth / imageAspectRatio;
//       displayOffsetX = 0;
//       displayOffsetY = (containerHeight - displayHeight) / 2;
//     } else {
//       displayWidth = containerHeight * imageAspectRatio;
//       displayHeight = containerHeight;
//       displayOffsetX = (containerWidth - displayWidth) / 2;
//       displayOffsetY = 0;
//     }
//
//     if (displayWidth <= 0 || displayHeight <= 0) {
//       return Offset.zero;
//     }
//
//     final relativeX = (screenPosition.dx - displayOffsetX) / displayWidth;
//     final relativeY = (screenPosition.dy - displayOffsetY) / displayHeight;
//
//     if (!relativeX.isFinite || !relativeY.isFinite) {
//       return Offset.zero;
//     }
//
//     final imageX = (relativeX * imageWidth).clamp(0.0, imageWidth);
//     final imageY = (relativeY * imageHeight).clamp(0.0, imageHeight);
//
//     return Offset(imageX, imageY);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
//         final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
//
//         return GestureDetector(
//           onTapDown: null,
//           onLongPressStart: _onLongPressStart,
//           onLongPressMoveUpdate: _onLongPressMoveUpdate,
//           onLongPressEnd: _onLongPressEnd,
//           child: SizedBox(
//             width: width,
//             height: height,
//             child: Stack(
//               children: [
//                 if (_imageLoaded && _image != null)
//                   RepaintBoundary(
//                     key: widget.repaintBoundaryKey,
//                     child: InteractiveViewer(
//                       transformationController: _transformationController,
//                       minScale: 1.0,
//                       maxScale: 50.0,
//                       child: SizedBox(
//                         width: double.infinity,
//                         height: double.infinity,
//                         child: _arrowAnimation != null
//                             ? AnimatedBuilder(
//                           animation: _arrowAnimation!,
//                           builder: (context, child) {
//                             return CustomPaint(
//                               painter: _ImagePainter(
//                                 _image!,widget.isTitleBulletHole,
//                                 bulletHoles: widget.bulletHoles,
//                                 ringDiameterPixels: widget.ringDiameterPixels,
//                                 groupCenter: widget.groupCenter,
//                                 groupRadius: widget.groupRadius,
//                                 highlightBulletHole: widget.highlightBulletHole,
//                                 arrowOffset: _arrowAnimation!.value,
//                               ),
//                               size: Size(width, height),
//                             );
//                           },
//                         )
//                             : CustomPaint(
//                           painter: _ImagePainter(
//                             _image!,widget.isTitleBulletHole,
//                             bulletHoles: widget.bulletHoles,
//                             ringDiameterPixels: widget.ringDiameterPixels,
//                             groupCenter: widget.groupCenter,
//                             groupRadius: widget.groupRadius,
//                             highlightBulletHole: widget.highlightBulletHole,
//                             arrowOffset: 0.0,
//                           ),
//                           size: Size(width, height),
//                         ),
//                       ),
//                     ),
//                   )
//                 else
//                   Container(
//                     width: double.infinity,
//                     height: double.infinity,
//                     color: Colors.grey[200],
//                     child: Center(
//                       child: Icon(
//                         Icons.image,
//                         size: 50,
//                         color: Colors.grey[400],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _ImagePainter extends CustomPainter {
//   final ui.Image image;
//   final List<BulletHole>? bulletHoles;
//   final double? ringDiameterPixels;
//   final Offset? groupCenter;
//   final double? groupRadius;
//   final Offset? highlightBulletHole;
//   final double arrowOffset;
//   final bool isTitleBulletHole;
//
//   _ImagePainter(
//       this.image, this.isTitleBulletHole, {
//         this.bulletHoles,
//         this.ringDiameterPixels,
//         this.groupCenter,
//         this.groupRadius,
//         this.highlightBulletHole,
//         this.arrowOffset = 0.0,
//       });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (size.width <= 0 || size.height <= 0 || image.width <= 0 || image.height <= 0) {
//       return;
//     }
//
//     final imageWidth = image.width.toDouble();
//     final imageHeight = image.height.toDouble();
//     final canvasWidth = size.width;
//     final canvasHeight = size.height;
//
//     final imageAspectRatio = imageWidth / imageHeight;
//     final canvasAspectRatio = canvasWidth / canvasHeight;
//
//     if (!imageAspectRatio.isFinite || !canvasAspectRatio.isFinite) {
//       return;
//     }
//
//     late Rect srcRect, dstRect;
//     late double displayWidth, displayHeight, displayOffsetX, displayOffsetY;
//
//     if (imageAspectRatio > canvasAspectRatio) {
//       displayHeight = canvasWidth / imageAspectRatio;
//       displayOffsetY = (canvasHeight - displayHeight) / 2;
//       displayOffsetX = 0;
//       displayWidth = canvasWidth;
//
//       srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
//       dstRect = Rect.fromLTWH(0, displayOffsetY, canvasWidth, displayHeight);
//     } else {
//       displayWidth = canvasHeight * imageAspectRatio;
//       displayOffsetX = (canvasWidth - displayWidth) / 2;
//       displayOffsetY = 0;
//       displayHeight = canvasHeight;
//
//       srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
//       dstRect = Rect.fromLTWH(displayOffsetX, 0, displayWidth, canvasHeight);
//     }
//
//     if (dstRect.width > 0 && dstRect.height > 0) {
//       canvas.drawImageRect(
//         image,
//         srcRect,
//         dstRect,
//         Paint()..filterQuality = FilterQuality.high,
//       );
//     }
//
//     // Draw rings for bullet holes with index labels
//     if (bulletHoles != null && bulletHoles!.isNotEmpty) {
//       for (final hole in bulletHoles!) {
//         final screenCoord = _imageToScreenCoordinates(
//           Offset(hole.cxPx, hole.cyPx),
//           imageWidth,
//           imageHeight,
//           displayWidth,
//           displayHeight,
//           displayOffsetX,
//           displayOffsetY,
//         );
//
//         final radius = ringDiameterPixels != null
//             ? (ringDiameterPixels ?? 9.08) * (displayWidth / imageWidth)
//             : 5.0;
//
//         // Draw ring
//         final ringPaint = Paint()
//           ..color = _getColorForScore(hole.score)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 0.8;
//
//         canvas.drawCircle(screenCoord, radius, ringPaint);
//
//         // Draw index label on top of the ring
//         final textSpan = TextSpan(
//           text: 'S${hole.index}',
//           style: TextStyle(
//             color: Colors.deepOrangeAccent,
//             fontSize: 6,
//             fontWeight: FontWeight.bold,
//             shadows: [
//               Shadow(
//                 color: Colors.black,
//                 blurRadius: 3,
//                 offset: Offset(0.5, 0.5),
//               ),
//             ],
//           ),
//         );
//
//         final textPainter = TextPainter(
//           text: textSpan,
//           textAlign: TextAlign.center,
//           textDirection: TextDirection.ltr,
//         );
//
//         textPainter.layout();
//
//         final textOffset = Offset(
//           screenCoord.dx - (textPainter.width / 2),
//           screenCoord.dy - radius - textPainter.height - 1,
//         );
//
//         isTitleBulletHole?textPainter.paint(canvas, textOffset):null;
//       }
//     }
//
//     // Draw highlight arrow if highlightBulletHole is provided
//     if (highlightBulletHole != null) {
//       final highlightScreenCoord = _imageToScreenCoordinates(
//         highlightBulletHole!,
//         imageWidth,
//         imageHeight,
//         displayWidth,
//         displayHeight,
//         displayOffsetX,
//         displayOffsetY,
//       );
//
//       _drawArrow(canvas, highlightScreenCoord, arrowOffset);
//     }
//
//     // Draw group enclosing circle
//     if (groupCenter != null && groupRadius != null) {
//       final screenCoord = _imageToScreenCoordinates(
//         groupCenter!,
//         imageWidth,
//         imageHeight,
//         displayWidth,
//         displayHeight,
//         displayOffsetX,
//         displayOffsetY,
//       );
//
//       final scaledRadius = groupRadius!;
//
//       final groupPaint = Paint()
//         ..color = Colors.green
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 0.8;
//
//       canvas.drawCircle(screenCoord, scaledRadius * (displayWidth / imageWidth), groupPaint);
//     }
//   }
//
//   void _drawArrow(Canvas canvas, Offset target, double offset) {
//     final arrowPaint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.fill;
//
//     final arrowStrokePaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     // Arrow pointing down towards the bullet hole
//     final arrowSize = 15.0;
//     final arrowTip = Offset(target.dx, target.dy - 5 - offset);
//     final arrowLeft = Offset(target.dx - arrowSize / 2, target.dy - 60 - offset);
//     final arrowRight = Offset(target.dx + arrowSize / 2, target.dy - 60 - offset);
//     final arrowBack = Offset(target.dx, target.dy - 50 - offset);
//
//     final arrowPath = Path()
//       ..moveTo(arrowTip.dx, arrowTip.dy)
//       ..lineTo(arrowLeft.dx, arrowLeft.dy)
//       ..lineTo(arrowBack.dx, arrowBack.dy)
//       ..lineTo(arrowRight.dx, arrowRight.dy)
//       ..close();
//
//     // Draw outline
//     canvas.drawPath(arrowPath, arrowStrokePaint);
//     // Draw fill
//     canvas.drawPath(arrowPath, arrowPaint);
//   }
//
//   Color _getColorForScore(int score) {
//     if (score >= 10) return Colors.orange;
//     if (score >= 8) return Colors.orange;
//     if (score >= 6) return Colors.orange;
//     return Colors.orange;
//   }
//
//   Offset _imageToScreenCoordinates(
//       Offset imageCoord,
//       double imageWidth,
//       double imageHeight,
//       double displayWidth,
//       double displayHeight,
//       double displayOffsetX,
//       double displayOffsetY,
//       ) {
//     final relativeX = imageCoord.dx / imageWidth;
//     final relativeY = imageCoord.dy / imageHeight;
//
//     final screenX = displayOffsetX + (relativeX * displayWidth);
//     final screenY = displayOffsetY + (relativeY * displayHeight);
//
//     return Offset(screenX, screenY);
//   }
//
//   @override
//   bool shouldRepaint(covariant _ImagePainter oldDelegate) {
//     return oldDelegate.image != image ||
//         oldDelegate.bulletHoles != bulletHoles ||
//         oldDelegate.ringDiameterPixels != ringDiameterPixels ||
//         oldDelegate.groupCenter != groupCenter ||
//         oldDelegate.groupRadius != groupRadius ||
//         oldDelegate.highlightBulletHole != highlightBulletHole ||
//         oldDelegate.arrowOffset != arrowOffset;
//   }
// }