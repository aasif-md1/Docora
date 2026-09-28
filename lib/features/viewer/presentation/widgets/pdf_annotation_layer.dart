import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/features/viewer/domain/models/pdf_annotation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PdfAnnotationLayer extends StatefulWidget {
  const PdfAnnotationLayer({
    required this.currentPage,
    required this.activeTool,
    required this.activeColor,
    required this.pageStrokes,
    required this.pageNotes,
    required this.pageSignatures,
    required this.onStrokesUpdated,
    required this.onNotesUpdated,
    required this.onSignaturesUpdated,
    super.key,
  });

  final int currentPage;
  final AnnotationTool activeTool;
  final Color activeColor;
  final List<PdfStroke> pageStrokes;
  final List<PdfTextAnnotation> pageNotes;
  final List<PdfSignatureAnnotation> pageSignatures;
  final ValueChanged<List<PdfStroke>> onStrokesUpdated;
  final ValueChanged<List<PdfTextAnnotation>> onNotesUpdated;
  final ValueChanged<List<PdfSignatureAnnotation>> onSignaturesUpdated;

  @override
  State<PdfAnnotationLayer> createState() => _PdfAnnotationLayerState();
}

class _PdfAnnotationLayerState extends State<PdfAnnotationLayer> {
  List<StrokePoint>? _currentStroke;

  bool get _isDrawingTool =>
      widget.activeTool == AnnotationTool.pen ||
      widget.activeTool == AnnotationTool.highlighter;

  void _onPanStart(DragDownDetails details) {
    if (!_isDrawingTool && widget.activeTool != AnnotationTool.eraser) return;

    final pos = details.localPosition;
    if (widget.activeTool == AnnotationTool.eraser) {
      _eraseNear(pos);
      return;
    }

    setState(() {
      _currentStroke = [StrokePoint(pos.dx, pos.dy)];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawingTool && widget.activeTool != AnnotationTool.eraser) return;

    final pos = details.localPosition;
    if (widget.activeTool == AnnotationTool.eraser) {
      _eraseNear(pos);
      return;
    }

    setState(() {
      _currentStroke?.add(StrokePoint(pos.dx, pos.dy));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      final isHighlighter = widget.activeTool == AnnotationTool.highlighter;
      final stroke = PdfStroke(
        points: List.from(_currentStroke!),
        color: isHighlighter
            ? widget.activeColor.withValues(alpha: 0.38)
            : widget.activeColor,
        width: isHighlighter ? 18.0 : 3.0,
        isHighlighter: isHighlighter,
      );

      final updated = List<PdfStroke>.from(widget.pageStrokes)..add(stroke);
      widget.onStrokesUpdated(updated);
      setState(() {
        _currentStroke = null;
      });
    }
  }

  void _eraseNear(Offset pos) {
    // Erase strokes within 20px
    final remaining = widget.pageStrokes.where((stroke) {
      for (final pt in stroke.points) {
        if ((Offset(pt.dx, pt.dy) - pos).distance < 24.0) {
          return false;
        }
      }
      return true;
    }).toList();

    if (remaining.length != widget.pageStrokes.length) {
      AppMotion.subtleHaptic();
      widget.onStrokesUpdated(remaining);
    }
  }

  Future<void> _onTapDown(TapDownDetails details) async {
    if (widget.activeTool == AnnotationTool.note) {
      final size = MediaQuery.of(context).size;
      final xRatio = details.localPosition.dx / size.width;
      final yRatio = details.localPosition.dy / size.height;

      final text = await _promptNoteText(context);
      if (text != null && text.isNotEmpty) {
        final note = PdfTextAnnotation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          page: widget.currentPage,
          xRatio: xRatio,
          yRatio: yRatio,
          content: text,
          color: widget.activeColor,
        );
        widget.onNotesUpdated(List.from(widget.pageNotes)..add(note));
      }
    }
  }

  Future<String?> _promptNoteText(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sticky Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your note here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final absorbsGestures = widget.activeTool == AnnotationTool.none;

    return IgnorePointer(
      ignoring: absorbsGestures,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            // Strokes custom paint
            CustomPaint(
              painter: _AnnotationPainter(
                strokes: widget.pageStrokes,
                activeStroke: _currentStroke,
                activeColor: widget.activeTool == AnnotationTool.highlighter
                    ? widget.activeColor.withValues(alpha: 0.38)
                    : widget.activeColor,
                activeWidth: widget.activeTool == AnnotationTool.highlighter ? 18.0 : 3.0,
                isHighlighter: widget.activeTool == AnnotationTool.highlighter,
              ),
              size: Size.infinite,
            ),

            // Note pins
            ...widget.pageNotes.map((note) => _buildNotePin(context, note)),

            // Signatures
            ...widget.pageSignatures.map((sig) => _buildSignature(context, sig)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotePin(BuildContext context, PdfTextAnnotation note) {
    final size = MediaQuery.of(context).size;
    final left = note.xRatio * size.width;
    final top = note.yRatio * size.height;

    return Positioned(
      left: left - 14,
      top: top - 14,
      child: GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Note'),
              content: Text(note.content),
              actions: [
                TextButton(
                  onPressed: () {
                    widget.onNotesUpdated(
                      widget.pageNotes.where((n) => n.id != note.id).toList(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete', style: TextStyle(color: AppColors.error500)),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: note.color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(LucideIcons.sticky_note, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSignature(BuildContext context, PdfSignatureAnnotation sig) {
    final size = MediaQuery.of(context).size;
    final left = sig.xRatio * size.width;
    final top = sig.yRatio * size.height;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withAlpha(100), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          size: const Size(140, 60),
          painter: _AnnotationPainter(
            strokes: sig.strokes,
            activeStroke: null,
            activeColor: Colors.black,
            activeWidth: 2.0,
            isHighlighter: false,
          ),
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  _AnnotationPainter({
    required this.strokes,
    required this.activeStroke,
    required this.activeColor,
    required this.activeWidth,
    required this.isHighlighter,
  });

  final List<PdfStroke> strokes;
  final List<StrokePoint>? activeStroke;
  final Color activeColor;
  final double activeWidth;
  final bool isHighlighter;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw existing strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = stroke.isHighlighter ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // 2. Draw currently drawing stroke
    if (activeStroke != null && activeStroke!.isNotEmpty) {
      final paint = Paint()
        ..color = activeColor
        ..strokeCap = isHighlighter ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = activeWidth
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(activeStroke!.first.dx, activeStroke!.first.dy);
      for (int i = 1; i < activeStroke!.length; i++) {
        path.lineTo(activeStroke![i].dx, activeStroke![i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
