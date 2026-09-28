import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:docora/features/viewer/domain/models/pdf_annotation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PdfSignatureDialog extends StatefulWidget {
  const PdfSignatureDialog({super.key});

  static Future<List<PdfStroke>?> show(BuildContext context) {
    return showDialog<List<PdfStroke>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PdfSignatureDialog(),
    );
  }

  @override
  State<PdfSignatureDialog> createState() => _PdfSignatureDialogState();
}

class _PdfSignatureDialogState extends State<PdfSignatureDialog> {
  final List<List<StrokePoint>> _strokes = [];
  List<StrokePoint>? _currentStroke;
  Color _strokeColor = Colors.black;

  final List<Color> _colors = [
    Colors.black,
    const Color(0xFF1E40AF), // Navy Blue
    const Color(0xFF991B1B), // Dark Red
    const Color(0xFF065F46), // Forest Green
  ];

  void _clear() {
    AppMotion.subtleHaptic();
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _onPanStart(DragDownDetails details) {
    final pos = details.localPosition;
    setState(() {
      _currentStroke = [StrokePoint(pos.dx, pos.dy)];
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = details.localPosition;
    setState(() {
      _currentStroke?.add(StrokePoint(pos.dx, pos.dy));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  void _save() {
    if (_strokes.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    final result = _strokes
        .map((points) => PdfStroke(
              points: points,
              color: _strokeColor,
              width: 3.0,
              isHighlighter: false,
            ))
        .toList();

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.pen_tool, size: 20, color: AppColors.primary500),
                const SizedBox(width: 8),
                Text(
                  'Draw Signature',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sign inside the box below with your finger',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),

            // Drawing Pad Canvas
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Stack(
                  children: [
                    // Baseline indicator
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 45,
                      child: Container(
                        height: 1,
                        color: Colors.black12,
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      bottom: 48,
                      child: Text(
                        'x',
                        style: TextStyle(color: Colors.black26, fontSize: 18),
                      ),
                    ),
                    GestureDetector(
                      onPanDown: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _SignaturePainter(strokes: _strokes, color: _strokeColor),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Color Selector & Clear
            Row(
              children: [
                ..._colors.map((c) => GestureDetector(
                      onTap: () => setState(() => _strokeColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _strokeColor == c ? AppColors.primary500 : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    )),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(LucideIcons.trash, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Save / Cancel Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DocoraButton(
                    label: 'Apply Signature',
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.color});

  final List<List<StrokePoint>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
