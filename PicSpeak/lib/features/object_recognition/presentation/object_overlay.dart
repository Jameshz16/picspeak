import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ObjectOverlay extends StatefulWidget {
  final String photoPath;
  final Rect? boundingBox;

  const ObjectOverlay({
    super.key,
    required this.photoPath,
    this.boundingBox,
  });

  @override
  State<ObjectOverlay> createState() => _ObjectOverlayState();
}

class _ObjectOverlayState extends State<ObjectOverlay> {
  double? _imageWidth;
  double? _imageHeight;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final file = File(widget.photoPath);
    if (!file.existsSync()) {
      setState(() => _hasError = true);
      return;
    }

    final imageProvider = FileImage(file);
    final stream = imageProvider.resolve(const ImageConfiguration());
    
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
          stream.removeListener(listener);
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() => _hasError = true);
          stream.removeListener(listener);
        }
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetWidth = constraints.maxWidth;
        final widgetHeight = constraints.maxHeight;

        final isImageLoaded = _imageWidth != null && _imageHeight != null;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.file(
              File(widget.photoPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
            // Scanner Overlay
            if (isImageLoaded && widget.boundingBox != null)
              CustomPaint(
                size: Size(widgetWidth, widgetHeight),
                painter: _ScannerOverlayPainter(
                  boundingBox: widget.boundingBox!,
                  imageWidth: _imageWidth!,
                  imageHeight: _imageHeight!,
                  widgetWidth: widgetWidth,
                  widgetHeight: widgetHeight,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect boundingBox;
  final double imageWidth;
  final double imageHeight;
  final double widgetWidth;
  final double widgetHeight;

  _ScannerOverlayPainter({
    required this.boundingBox,
    required this.imageWidth,
    required this.imageHeight,
    required this.widgetWidth,
    required this.widgetHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate BoxFit.cover mapping scales and offsets
    final double scaleX = widgetWidth / imageWidth;
    final double scaleY = widgetHeight / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double scaledWidth = imageWidth * scale;
    final double scaledHeight = imageHeight * scale;

    final double offsetX = (widgetWidth - scaledWidth) / 2;
    final double offsetY = (widgetHeight - scaledHeight) / 2;

    // 2. Map bounding box from image space to widget space
    final double mappedLeft = boundingBox.left * scale + offsetX;
    final double mappedTop = boundingBox.top * scale + offsetY;
    final double mappedRight = boundingBox.right * scale + offsetX;
    final double mappedBottom = boundingBox.bottom * scale + offsetY;

    final Rect mappedRect = Rect.fromLTRB(
      mappedLeft.clamp(0.0, widgetWidth),
      mappedTop.clamp(0.0, widgetHeight),
      mappedRight.clamp(0.0, widgetWidth),
      mappedBottom.clamp(0.0, widgetHeight),
    );

    // 3. Draw background dim mask with an even-odd punched hole
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, widgetWidth, widgetHeight))
      ..addRRect(RRect.fromRectAndRadius(mappedRect, const Radius.circular(16)));
    
    maskPath.fillType = PathFillType.evenOdd;

    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = ui.PaintingStyle.fill;

    canvas.drawPath(maskPath, maskPaint);

    // 4. Draw cyan glowing outline around the target object
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 4.0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(mappedRect, const Radius.circular(16)),
      glowPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(mappedRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.boundingBox != boundingBox ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.widgetWidth != widgetWidth ||
        oldDelegate.widgetHeight != widgetHeight;
  }
}
