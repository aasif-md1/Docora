import 'dart:io';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum CropAspectRatio {
  free('Free', null),
  square('1:1', 1.0),
  photo43('4:3', 4.0 / 3.0),
  wide169('16:9', 16.0 / 9.0),
  a4Doc('A4 Doc', 1.0 / 1.414);

  const CropAspectRatio(this.label, this.ratio);
  final String label;
  final double? ratio; // width / height
}

/// Standalone interactive image crop and rotate screen.
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    required this.imagePath,
    super.key,
  });

  final String imagePath;

  static Future<String?> show(BuildContext context, String imagePath) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageCropScreen(imagePath: imagePath),
      ),
    );
  }

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  Uint8List? _imageBytes;
  int _imageWidth = 1;
  int _imageHeight = 1;
  bool _isLoading = true;
  bool _isSaving = false;

  int _rotationQuarterTurns = 0;
  CropAspectRatio _selectedRatio = CropAspectRatio.free;

  // Normalized crop rectangle: 0.0 to 1.0
  Rect _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null && mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageWidth = decoded.width;
          _imageHeight = decoded.height;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  void _rotateClockwise() {
    AppMotion.subtleHaptic();
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      // Reset crop rect when rotated
      _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90);
    });
  }

  void _setAspectRatio(CropAspectRatio ratio) {
    AppMotion.subtleHaptic();
    setState(() {
      _selectedRatio = ratio;
      if (ratio.ratio == null) {
        // Freeform
        return;
      }

      // Compute aspect ratio constraint relative to current image orientation
      final isRotated90 = _rotationQuarterTurns % 2 != 0;
      final curW = isRotated90 ? _imageHeight : _imageWidth;
      final curH = isRotated90 ? _imageWidth : _imageHeight;
      final imgAspect = curW / curH;

      final targetRatio = ratio.ratio!;
      double newW = 0.85;
      double newH = (newW / targetRatio) * imgAspect;

      if (newH > 0.85) {
        newH = 0.85;
        newW = (newH * targetRatio) / imgAspect;
      }

      final left = (1.0 - newW) / 2;
      final top = (1.0 - newH) / 2;
      _cropRect = Rect.fromLTWH(left.clamp(0.0, 0.9), top.clamp(0.0, 0.9), newW.clamp(0.1, 1.0), newH.clamp(0.1, 1.0));
    });
  }

  void _resetCrop() {
    AppMotion.subtleHaptic();
    setState(() {
      _rotationQuarterTurns = 0;
      _selectedRatio = CropAspectRatio.free;
      _cropRect = const Rect.fromLTWH(0.02, 0.02, 0.96, 0.96);
    });
  }

  Future<void> _applyAndSave() async {
    if (_imageBytes == null) return;
    AppMotion.subtleHaptic();
    setState(() => _isSaving = true);

    try {
      final inputBytes = _imageBytes!;
      final quarterTurns = _rotationQuarterTurns;
      final crop = _cropRect;

      final croppedPath = await compute(_processCropInBackground, {
        'bytes': inputBytes,
        'quarterTurns': quarterTurns,
        'cropLeft': crop.left,
        'cropTop': crop.top,
        'cropWidth': crop.width,
        'cropHeight': crop.height,
      });

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, croppedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save cropped image: $e')),
        );
      }
    }
  }

  static Future<String> _processCropInBackground(Map<String, dynamic> params) async {
    final bytes = params['bytes'] as Uint8List;
    final quarterTurns = params['quarterTurns'] as int;
    final cropLeft = params['cropLeft'] as double;
    final cropTop = params['cropTop'] as double;
    final cropWidth = params['cropWidth'] as double;
    final cropHeight = params['cropHeight'] as double;

    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode image');
    }

    // 1. Rotate if needed
    if (quarterTurns % 4 != 0) {
      decoded = img.copyRotate(decoded, angle: (quarterTurns % 4) * 90);
    }

    // 2. Crop
    final imgW = decoded.width;
    final imgH = decoded.height;

    final x = (cropLeft * imgW).round().clamp(0, imgW - 1);
    final y = (cropTop * imgH).round().clamp(0, imgH - 1);
    final w = (cropWidth * imgW).round().clamp(1, imgW - x);
    final h = (cropHeight * imgH).round().clamp(1, imgH - y);

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);

    // 3. Encode to JPG
    final encoded = img.encodeJpg(cropped, quality: 92);

    final tempDir = await getTemporaryDirectory();
    final outPath = '${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded);

    return outPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Crop & Adjust', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotate_cw),
            tooltip: 'Rotate 90°',
            onPressed: _isLoading ? null : _rotateClockwise,
          ),
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            tooltip: 'Reset',
            onPressed: _isLoading ? null : _resetCrop,
          ),
          TextButton.icon(
            onPressed: (_isLoading || _isSaving) ? null : _applyAndSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.check, size: 18, color: Colors.white),
            label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : Column(
              children: [
                // Crop Viewport Canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isRotated90 = _rotationQuarterTurns % 2 != 0;
                        final displayW = (isRotated90 ? _imageHeight : _imageWidth).toDouble();
                        final displayH = (isRotated90 ? _imageWidth : _imageHeight).toDouble();
                        final imageRatio = displayW / (displayH > 0 ? displayH : 1);

                        double boxW = constraints.maxWidth;
                        double boxH = boxW / imageRatio;
                        if (boxH > constraints.maxHeight) {
                          boxH = constraints.maxHeight;
                          boxW = boxH * imageRatio;
                        }

                        return Center(
                          child: SizedBox(
                            width: boxW,
                            height: boxH,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Base Rotated Image
                                Positioned.fill(
                                  child: RotatedBox(
                                    quarterTurns: _rotationQuarterTurns,
                                    child: Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),

                                // Interactive Crop Overlay
                                Positioned.fill(
                                  child: _CropOverlay(
                                    cropRect: _cropRect,
                                    aspectRatio: _selectedRatio.ratio,
                                    onCropChanged: (newRect) {
                                      setState(() => _cropRect = newRect);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Aspect Ratio Selector Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                  color: const Color(0xFF13131A),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: CropAspectRatio.values.map((ratio) {
                        final isSelected = _selectedRatio == ratio;
                        return ChoiceChip(
                          label: Text(ratio.label),
                          selected: isSelected,
                          selectedColor: AppColors.primary500,
                          backgroundColor: const Color(0xFF232330),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => _setAspectRatio(ratio),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Renders a crop rectangle overlay with interactive draggable corner/edge handles.
class _CropOverlay extends StatefulWidget {
  const _CropOverlay({
    required this.cropRect,
    required this.onCropChanged,
    this.aspectRatio,
  });

  final Rect cropRect; // Normalized 0..1
  final ValueChanged<Rect> onCropChanged;
  final double? aspectRatio;

  @override
  State<_CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<_CropOverlay> {
  int _activeHandle = -1; // 0: TopLeft, 1: TopRight, 2: BottomRight, 3: BottomLeft, 4: Inside (move)

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final pixelRect = Rect.fromLTWH(
          widget.cropRect.left * w,
          widget.cropRect.top * h,
          widget.cropRect.width * w,
          widget.cropRect.height * h,
        );

        return GestureDetector(
          onPanDown: (details) {
            final p = details.localPosition;
            final hitPadding = 24.0;

            if ((p - pixelRect.topLeft).distance <= hitPadding) {
              _activeHandle = 0;
            } else if ((p - pixelRect.topRight).distance <= hitPadding) {
              _activeHandle = 1;
            } else if ((p - pixelRect.bottomRight).distance <= hitPadding) {
              _activeHandle = 2;
            } else if ((p - pixelRect.bottomLeft).distance <= hitPadding) {
              _activeHandle = 3;
            } else if (pixelRect.contains(p)) {
              _activeHandle = 4;
            } else {
              _activeHandle = -1;
            }
          },
          onPanUpdate: (details) {
            if (_activeHandle == -1) return;

            final dx = details.delta.dx / w;
            final dy = details.delta.dy / h;

            double l = widget.cropRect.left;
            double t = widget.cropRect.top;
            double r = widget.cropRect.right;
            double b = widget.cropRect.bottom;

            final minSize = 0.12;

            if (_activeHandle == 4) {
              // Move whole rectangle
              final width = r - l;
              final height = b - t;
              l = (l + dx).clamp(0.0, 1.0 - width);
              t = (t + dy).clamp(0.0, 1.0 - height);
              r = l + width;
              b = t + height;
            } else if (_activeHandle == 0) {
              // Top-Left
              l = (l + dx).clamp(0.0, r - minSize);
              t = (t + dy).clamp(0.0, b - minSize);
            } else if (_activeHandle == 1) {
              // Top-Right
              r = (r + dx).clamp(l + minSize, 1.0);
              t = (t + dy).clamp(0.0, b - minSize);
            } else if (_activeHandle == 2) {
              // Bottom-Right
              r = (r + dx).clamp(l + minSize, 1.0);
              b = (b + dy).clamp(t + minSize, 1.0);
            } else if (_activeHandle == 3) {
              // Bottom-Left
              l = (l + dx).clamp(0.0, r - minSize);
              b = (b + dy).clamp(t + minSize, 1.0);
            }

            widget.onCropChanged(Rect.fromLTRB(l, t, r, b));
          },
          onPanEnd: (_) => _activeHandle = -1,
          child: CustomPaint(
            size: Size(w, h),
            painter: _CropPainter(pixelRect),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Semi-transparent dark background outside the crop rect
    final bgPaint = Paint()..color = Colors.black.withAlpha(150);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // 2. Crop border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, borderPaint);

    // 3. Rule of Thirds grid lines inside crop rect
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final x1 = rect.left + rect.width / 3;
    final x2 = rect.left + (rect.width * 2) / 3;
    final y1 = rect.top + rect.height / 3;
    final y2 = rect.top + (rect.height * 2) / 3;

    canvas.drawLine(Offset(x1, rect.top), Offset(x1, rect.bottom), gridPaint);
    canvas.drawLine(Offset(x2, rect.top), Offset(x2, rect.bottom), gridPaint);
    canvas.drawLine(Offset(rect.left, y1), Offset(rect.right, y1), gridPaint);
    canvas.drawLine(Offset(rect.left, y2), Offset(rect.right, y2), gridPaint);

    // 4. Corner Handles (L-shaped accents)
    final handlePaint = Paint()
      ..color = AppColors.primary500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const arm = 18.0;

    // Top-Left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(arm, 0), handlePaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, arm), handlePaint);

    // Top-Right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-arm, 0), handlePaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, arm), handlePaint);

    // Bottom-Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(arm, 0), handlePaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -arm), handlePaint);

    // Bottom-Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-arm, 0), handlePaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -arm), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) => oldDelegate.rect != rect;
}
